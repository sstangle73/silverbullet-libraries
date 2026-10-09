# Security

## Reporting a vulnerability

Please report a security problem privately, not in a public issue: use **[Report a vulnerability](https://github.com/sstangle73/silverbullet-libraries/security/advisories/new)** on the GitHub repository's *Security* tab. Only you and the maintainer see the report.

Say what you can of:
- which library, and its version;
- how to reproduce it, or a proof of concept;
- what someone could do with it.

## What happens next

- You'll hear back within 7 days.
- Once it's confirmed, it gets fixed, and a GitHub security advisory is published that credits you, unless you'd rather not be named. A CVE is requested through GitHub when the problem warrants one.
- Please keep it private until a fix is out, or for 90 days after your report, whichever comes first.

This is a one-person project, and reports aren't paid.

## Supported versions

Only each library's latest version gets fixes. Storie Check shows which version a space runs.

## What's in scope

The libraries in [`src/`](src/), the repository page [`Repositories/storie.md`](Repositories/storie.md) and the scripts in [`tools/`](tools/). These matter most:
- **GM Kit's publishing:** anything that puts what the GM hasn't revealed into the players' copy.
- **Content run as code:** a page's text, or a character imported by GM Beyond, that ends up evaluated as Space Lua.
- **Writes outside a library's own pages,** or into a space other than the one it was installed in.

Out of scope: SilverBullet itself (report its problems to [SilverBullet](https://github.com/silverbulletmd/silverbullet)), and a space's own access control.
