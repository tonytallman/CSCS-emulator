#!/usr/bin/env python3
"""Upload App Store listing localizations from repo markdown via App Store Connect API."""

from __future__ import annotations

import argparse
import json
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path

try:
    import jwt
except ImportError:
    jwt = None  # type: ignore[assignment]

ROOT = Path(__file__).resolve().parent.parent
PBXPROJ = ROOT / "CSCSEmulator" / "CSCSEmulator.xcodeproj" / "project.pbxproj"
SUBMISSION_DOC = ROOT / "documentation" / "APP_STORE_SUBMISSION.md"
APP_STORE_DIR = ROOT / "documentation" / "app-store"

BUNDLE_ID = "com.tallmansoftware.csc-emulator"
API_BASE = "https://api.appstoreconnect.apple.com/v1"

EDITABLE_VERSION_STATES = {
    "PREPARE_FOR_SUBMISSION",
    "REJECTED",
    "DEVELOPER_REJECTED",
    "METADATA_REJECTED",
}

LOCALE_SOURCES: list[tuple[str, Path]] = [
    ("en-US", SUBMISSION_DOC),
    ("es-MX", APP_STORE_DIR / "es.md"),
    ("es-ES", APP_STORE_DIR / "es.md"),
    ("fr-FR", APP_STORE_DIR / "fr.md"),
    ("de-DE", APP_STORE_DIR / "de.md"),
    ("it", APP_STORE_DIR / "it.md"),
    ("pt-BR", APP_STORE_DIR / "pt-BR.md"),
    ("ja", APP_STORE_DIR / "ja.md"),
    ("ko", APP_STORE_DIR / "ko.md"),
    ("zh-Hans", APP_STORE_DIR / "zh-Hans.md"),
    ("zh-Hant", APP_STORE_DIR / "zh-Hant.md"),
]

LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotionalText": 170,
    "description": 4000,
    "whatsNew": 4000,
}


@dataclass(frozen=True)
class LocalizationMetadata:
    locale: str
    name: str
    subtitle: str
    promotional_text: str
    whats_new: str
    description: str
    keywords: str
    support_url: str
    marketing_url: str
    privacy_policy_url: str


class UploadError(Exception):
    pass


def read_marketing_version() -> str:
    text = PBXPROJ.read_text(encoding="utf-8")
    match = re.search(r"MARKETING_VERSION = ([^;]+);", text)
    if not match:
        raise UploadError(f"Could not read MARKETING_VERSION from {PBXPROJ}")
    return match.group(1).strip()


def extract_table_value(content: str, field: str) -> str | None:
    pattern = rf"\|\s*\*\*{re.escape(field)}\*\*\s*\|\s*(.+?)\s*\|"
    match = re.search(pattern, content)
    if not match:
        return None
    value = match.group(1).strip()
    if value.startswith("`") and value.endswith("`"):
        value = value[1:-1]
    return value


def extract_blockquote_after_heading(content: str, heading: str) -> str | None:
    section = re.search(
        rf"## {re.escape(heading)}[^\n]*\n+(>[^\n]+)",
        content,
        re.MULTILINE,
    )
    if not section:
        return None
    line = section.group(1)
    return line.lstrip(">").strip()


def extract_fenced_block_after_heading(content: str, heading: str) -> str | None:
    section_match = re.search(rf"## {re.escape(heading)}[^\n]*\n", content)
    if not section_match:
        return None
    rest = content[section_match.end():]
    next_heading = re.search(r"\n## ", rest)
    if next_heading:
        rest = rest[: next_heading.start()]
    fence_match = re.search(r"```\n(.*?)\n```", rest, re.DOTALL)
    if not fence_match:
        return None
    return fence_match.group(1).strip()


def parse_metadata_file(path: Path, locale: str, shared_urls: dict[str, str] | None) -> LocalizationMetadata:
    if not path.is_file():
        raise UploadError(f"Missing metadata file for {locale}: {path}")

    content = path.read_text(encoding="utf-8")

    name = extract_table_value(content, "App Name")
    subtitle = extract_table_value(content, "Subtitle")
    promotional_text = extract_blockquote_after_heading(content, "Promotional Text")
    whats_new = extract_fenced_block_after_heading(content, "What's New in This Version?")
    description = extract_fenced_block_after_heading(content, "Description")
    keywords = extract_fenced_block_after_heading(content, "Keywords")

    support_url = extract_table_value(content, "Support URL")
    marketing_url = extract_table_value(content, "Marketing URL")
    privacy_policy_url = extract_table_value(content, "Privacy Policy URL")

    if shared_urls:
        support_url = support_url or shared_urls.get("support")
        marketing_url = marketing_url or shared_urls.get("marketing")
        privacy_policy_url = privacy_policy_url or shared_urls.get("privacy")

    missing = [
        label
        for label, value in [
            ("App Name", name),
            ("Subtitle", subtitle),
            ("Promotional Text", promotional_text),
            ("What's New", whats_new),
            ("Description", description),
            ("Keywords", keywords),
            ("Support URL", support_url),
            ("Marketing URL", marketing_url),
            ("Privacy Policy URL", privacy_policy_url),
        ]
        if not value
    ]
    if missing:
        raise UploadError(f"{path}: missing required fields: {', '.join(missing)}")

    return LocalizationMetadata(
        locale=locale,
        name=name or "",
        subtitle=subtitle or "",
        promotional_text=promotional_text or "",
        whats_new=whats_new or "",
        description=description or "",
        keywords=keywords or "",
        support_url=support_url or "",
        marketing_url=marketing_url or "",
        privacy_policy_url=privacy_policy_url or "",
    )


def load_all_localizations() -> list[LocalizationMetadata]:
    english = parse_metadata_file(SUBMISSION_DOC, "en-US", shared_urls=None)
    shared_urls = {
        "support": english.support_url,
        "marketing": english.marketing_url,
        "privacy": english.privacy_policy_url,
    }

    localizations = [english]
    for locale, path in LOCALE_SOURCES[1:]:
        localizations.append(parse_metadata_file(path, locale, shared_urls=shared_urls))
    return localizations


def validate_localizations(localizations: list[LocalizationMetadata]) -> None:
    errors: list[str] = []
    for item in localizations:
        checks = [
            ("name", item.name, LIMITS["name"]),
            ("subtitle", item.subtitle, LIMITS["subtitle"]),
            ("promotionalText", item.promotional_text, LIMITS["promotionalText"]),
            ("whatsNew", item.whats_new, LIMITS["whatsNew"]),
            ("description", item.description, LIMITS["description"]),
            ("keywords", item.keywords, LIMITS["keywords"]),
        ]
        for field, value, limit in checks:
            if len(value) > limit:
                errors.append(
                    f"{item.locale} {field}: {len(value)} chars exceeds limit {limit}",
                )
    if errors:
        raise UploadError("Validation failed:\n" + "\n".join(f"  - {e}" for e in errors))


def discover_auth_key() -> tuple[Path, str]:
    env_path = Path(os.environ["APP_STORE_CONNECT_KEY_PATH"]).expanduser() if "APP_STORE_CONNECT_KEY_PATH" in os.environ else None
    if env_path and env_path.is_file():
        key_path = env_path
    else:
        key_dir = Path.home() / ".appstoreconnect" / "private_keys"
        if not key_dir.is_dir():
            raise UploadError(
                f"No API key found. Place AuthKey_<KEY_ID>.p8 in {key_dir} "
                "or set APP_STORE_CONNECT_KEY_PATH.",
            )
        keys = sorted(key_dir.glob("AuthKey_*.p8"))
        if not keys:
            raise UploadError(f"No AuthKey_*.p8 files in {key_dir}")

        if "APP_STORE_CONNECT_KEY_ID" in os.environ:
            key_id = os.environ["APP_STORE_CONNECT_KEY_ID"]
            key_path = key_dir / f"AuthKey_{key_id}.p8"
            if not key_path.is_file():
                raise UploadError(f"APP_STORE_CONNECT_KEY_ID={key_id} but {key_path} not found")
        elif len(keys) == 1:
            key_path = keys[0]
        else:
            raise UploadError(
                f"Multiple API keys in {key_dir}. Set APP_STORE_CONNECT_KEY_ID to choose one.",
            )

    key_id = os.environ.get("APP_STORE_CONNECT_KEY_ID")
    if not key_id:
        match = re.search(r"AuthKey_([A-Z0-9]+)\.p8$", key_path.name)
        if not match:
            raise UploadError(f"Could not parse key id from {key_path.name}")
        key_id = match.group(1)
    return key_path, key_id


def discover_issuer_id() -> str:
    if "APP_STORE_CONNECT_ISSUER_ID" in os.environ:
        return os.environ["APP_STORE_CONNECT_ISSUER_ID"].strip()

    issuer_file = Path.home() / ".appstoreconnect" / "issuer_id"
    if issuer_file.is_file():
        issuer_id = issuer_file.read_text(encoding="utf-8").strip()
        if issuer_id:
            return issuer_id

    raise UploadError(
        "Missing Issuer ID. Set APP_STORE_CONNECT_ISSUER_ID or create "
        f"{issuer_file} with the UUID from App Store Connect → Users and Access → "
        "Integrations → App Store Connect API.",
    )


def make_token(key_path: Path, key_id: str, issuer_id: str) -> str:
    if jwt is None:
        raise UploadError(
            "PyJWT is required. Install with: python3 -m pip install --user PyJWT cryptography",
        )

    private_key = key_path.read_text(encoding="utf-8")
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    headers = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def make_ssl_context() -> ssl.SSLContext:
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        pass

    for candidate in (
        "/etc/ssl/cert.pem",
        "/private/etc/ssl/cert.pem",
    ):
        if Path(candidate).is_file():
            return ssl.create_default_context(cafile=candidate)

    return ssl.create_default_context()


class AppStoreConnectClient:
    def __init__(self, token: str) -> None:
        self.token = token
        self.ssl_context = make_ssl_context()

    def request(
        self,
        method: str,
        path: str,
        *,
        query: dict[str, str] | None = None,
        body: dict | None = None,
    ) -> dict:
        url = f"{API_BASE}{path}"
        if query:
            url = f"{url}?{urllib.parse.urlencode(query)}"

        data = None
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
        }
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"

        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, context=self.ssl_context) as response:
                raw = response.read().decode("utf-8")
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            raise UploadError(f"{method} {path} failed ({error.code}): {detail}") from error

    def get(self, path: str, *, query: dict[str, str] | None = None) -> dict:
        return self.request("GET", path, query=query)

    def post(self, path: str, body: dict) -> dict:
        return self.request("POST", path, body=body)

    def patch(self, path: str, body: dict) -> dict:
        return self.request("PATCH", path, body=body)


def index_by_locale(items: list[dict]) -> dict[str, dict]:
    indexed: dict[str, dict] = {}
    for item in items:
        locale = item.get("attributes", {}).get("locale")
        if locale:
            indexed[locale] = item
    return indexed


def is_duplicate_entity_error(error: UploadError) -> bool:
    message = str(error)
    return "409" in message and "already exists" in message.lower()


def patch_app_info_localization(
    client: AppStoreConnectClient,
    localization_id: str,
    attributes: dict[str, str],
) -> None:
    client.patch(
        f"/appInfoLocalizations/{localization_id}",
        {
            "data": {
                "type": "appInfoLocalizations",
                "id": localization_id,
                "attributes": attributes,
            },
        },
    )


def patch_version_localization(
    client: AppStoreConnectClient,
    localization_id: str,
    attributes: dict[str, str],
) -> None:
    client.patch(
        f"/appStoreVersionLocalizations/{localization_id}",
        {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": localization_id,
                "attributes": attributes,
            },
        },
    )


def upsert_app_info_localization(
    client: AppStoreConnectClient,
    *,
    app_info_id: str,
    locale: str,
    attributes: dict[str, str],
    cache: dict[str, dict],
) -> None:
    if locale in cache:
        patch_app_info_localization(client, cache[locale]["id"], attributes)
        print(f"  PATCH appInfoLocalization {locale}")
        return

    try:
        client.post(
            "/appInfoLocalizations",
            {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": {
                        "locale": locale,
                        **attributes,
                    },
                    "relationships": {
                        "appInfo": {
                            "data": {"type": "appInfos", "id": app_info_id},
                        },
                    },
                },
            },
        )
        print(f"  POST appInfoLocalization {locale}")
    except UploadError as error:
        if not is_duplicate_entity_error(error):
            raise
        refreshed = client.get(
            f"/appInfos/{app_info_id}/appInfoLocalizations",
            query={"limit": "200"},
        )
        cache.update(index_by_locale(refreshed.get("data", [])))
        if locale not in cache:
            raise
        patch_app_info_localization(client, cache[locale]["id"], attributes)
        print(f"  PATCH appInfoLocalization {locale} (after duplicate)")


def upsert_version_localization(
    client: AppStoreConnectClient,
    *,
    version_id: str,
    locale: str,
    attributes: dict[str, str],
    cache: dict[str, dict],
) -> None:
    if locale in cache:
        patch_version_localization(client, cache[locale]["id"], attributes)
        print(f"  PATCH appStoreVersionLocalization {locale}")
        return

    try:
        client.post(
            "/appStoreVersionLocalizations",
            {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {
                        "locale": locale,
                        **attributes,
                    },
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version_id},
                        },
                    },
                },
            },
        )
        print(f"  POST appStoreVersionLocalization {locale}")
    except UploadError as error:
        if not is_duplicate_entity_error(error):
            raise
        refreshed = client.get(
            f"/appStoreVersions/{version_id}/appStoreVersionLocalizations",
            query={"limit": "200"},
        )
        cache.update(index_by_locale(refreshed.get("data", [])))
        if locale not in cache:
            raise
        patch_version_localization(client, cache[locale]["id"], attributes)
        print(f"  PATCH appStoreVersionLocalization {locale} (after duplicate)")


def upload_localizations(client: AppStoreConnectClient, localizations: list[LocalizationMetadata]) -> None:
    version_string = read_marketing_version()

    apps = client.get("/apps", query={"filter[bundleId]": BUNDLE_ID})
    app_data = apps.get("data", [])
    if not app_data:
        raise UploadError(f"No app found for bundle id {BUNDLE_ID}")
    app_id = app_data[0]["id"]

    versions = client.get(
        f"/apps/{app_id}/appStoreVersions",
        query={
            "filter[platform]": "IOS",
            "filter[versionString]": version_string,
            "limit": "10",
        },
    )
    version_data = versions.get("data", [])
    if not version_data:
        raise UploadError(
            f"No iOS App Store version {version_string} found. Create it in App Store Connect first.",
        )

    version = version_data[0]
    version_id = version["id"]
    version_state = version.get("attributes", {}).get("appStoreState", "")
    if version_state not in EDITABLE_VERSION_STATES:
        raise UploadError(
            f"Version {version_string} is in state {version_state!r} and cannot be edited. "
            f"Editable states: {', '.join(sorted(EDITABLE_VERSION_STATES))}.",
        )

    app_infos = client.get(f"/apps/{app_id}/appInfos", query={"limit": "20"})
    app_info_list = app_infos.get("data", [])
    app_info = next(
        (item for item in app_info_list if item.get("attributes", {}).get("appStoreState") == version_state),
        app_info_list[0] if app_info_list else None,
    )
    if app_info is None:
        raise UploadError("No appInfo resource found for this app")
    app_info_id = app_info["id"]

    info_locs = client.get(f"/appInfos/{app_info_id}/appInfoLocalizations", query={"limit": "200"})
    version_locs = client.get(
        f"/appStoreVersions/{version_id}/appStoreVersionLocalizations",
        query={"limit": "200"},
    )
    info_by_locale = index_by_locale(info_locs.get("data", []))
    version_by_locale = index_by_locale(version_locs.get("data", []))

    for item in localizations:
        info_attrs = {
            "name": item.name,
            "subtitle": item.subtitle,
            "privacyPolicyUrl": item.privacy_policy_url,
        }
        version_attrs = {
            "description": item.description,
            "keywords": item.keywords,
            "promotionalText": item.promotional_text,
            "whatsNew": item.whats_new,
            "supportUrl": item.support_url,
            "marketingUrl": item.marketing_url,
        }

        upsert_app_info_localization(
            client,
            app_info_id=app_info_id,
            locale=item.locale,
            attributes=info_attrs,
            cache=info_by_locale,
        )
        upsert_version_localization(
            client,
            version_id=version_id,
            locale=item.locale,
            attributes=version_attrs,
            cache=version_by_locale,
        )


def print_dry_run(localizations: list[LocalizationMetadata]) -> None:
    version_string = read_marketing_version()
    print(f"Would upload {len(localizations)} localizations for version {version_string}:")
    for item in localizations:
        print(f"\n=== {item.locale} ===")
        print(json.dumps(
            {
                "appInfoLocalization": {
                    "name": item.name,
                    "subtitle": item.subtitle,
                    "privacyPolicyUrl": item.privacy_policy_url,
                },
                "appStoreVersionLocalization": {
                    "description": item.description[:120] + ("…" if len(item.description) > 120 else ""),
                    "keywords": item.keywords,
                    "promotionalText": item.promotional_text,
                    "whatsNew": item.whats_new,
                    "supportUrl": item.support_url,
                    "marketingUrl": item.marketing_url,
                },
            },
            indent=2,
            ensure_ascii=False,
        ))


def run_self_test() -> None:
    localizations = load_all_localizations()
    validate_localizations(localizations)
    locales = [item.locale for item in localizations]
    expected = [locale for locale, _ in LOCALE_SOURCES]
    if locales != expected:
        raise UploadError(f"Locale order mismatch: got {locales}, expected {expected}")
    print(f"Self-test passed: {len(localizations)} locales parsed and validated.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and print payloads without calling App Store Connect",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Parse markdown and validate field limits only",
    )
    args = parser.parse_args()

    try:
        if args.self_test:
            run_self_test()
            return 0

        localizations = load_all_localizations()
        validate_localizations(localizations)

        if args.dry_run:
            print_dry_run(localizations)
            return 0

        key_path, key_id = discover_auth_key()
        issuer_id = discover_issuer_id()
        token = make_token(key_path, key_id, issuer_id)
        client = AppStoreConnectClient(token)

        print(f"Uploading {len(localizations)} App Store localizations…")
        upload_localizations(client, localizations)
        print("Upload complete.")
        return 0
    except UploadError as error:
        message = str(error)
        if "403" in message:
            print(
                f"Error: {error}\n\n"
                "If this is a permissions error, create a Team API key with the App Manager role, "
                "save it as ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8, and set "
                "APP_STORE_CONNECT_KEY_ID to that key id. Keep your existing Developer key.",
                file=sys.stderr,
            )
        else:
            print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
