# Reporting Security Issues

If you find a security vulnerability in AudioPouch, please report it privately via [GitHub Security Advisories](https://github.com/alzimerahmed/AudioPouch/security/advisories/new) or by opening a private issue at https://github.com/alzimerahmed/AudioPouch/issues, and allow us to respond before disclosing the issue publicly.

## App Transport Security

The iOS, watchOS, and tvOS property lists currently allow arbitrary network loads because podcast feeds and their media, artwork, and enclosure URLs are controlled by third parties; some still use plain HTTP. The Phase 9 static audit found roughly 290 `http://` references, mostly RSS namespaces and third-party feed/media URLs. Restricting these loads would break compatibility with those feeds.

The first-party API domains declared in `NSExceptionDomains` remain HTTPS-only (`NSExceptionAllowInsecureHTTPLoads` is `false`). The broad ATS setting is a compatibility trade-off, not permission for first-party API traffic to downgrade to HTTP. HTTP podcast traffic is not encrypted in transit; use trusted networks when listening to feeds that do not support HTTPS.

The app's show-notes and podcast-description views render formatted HTML locally with `loadHTMLString`; this does not require allowing arbitrary remote web content in a web view. All podcast-supplied HTML (show notes and rich podcast descriptions) is sanitized with SwiftSoup before rendering, and JavaScript is disabled in the show-notes web views. The first-party support view (Zendesk) is remote content that legitimately needs JavaScript and is out of scope of the local-HTML sanitization.
