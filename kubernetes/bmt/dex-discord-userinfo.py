"""Userinfo endpoint for Dex's oauth connector.

Dex reads one flat JSON document after login, but Discord splits the profile
and the guild roles across two calls, so this merges them.
"""

import json
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from socket import AF_INET6

API = os.environ.get("DISCORD_API", "https://discord.com/api/v10")
GUILD_ID = os.environ["DISCORD_GUILD_ID"]


def discord(path, authorization):
    request = urllib.request.Request(
        API + path,
        headers={
            "Authorization": authorization,
            # Discord rejects urllib's default User-Agent.
            "User-Agent": "DiscordBot (https://id.berkeley.mt, 1)",
        },
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        return json.load(response)


def userinfo(authorization):
    user = discord("/users/@me", authorization)
    try:
        roles = discord(f"/users/@me/guilds/{GUILD_ID}/member", authorization)["roles"]
    except urllib.error.HTTPError as error:
        # 404: not a member of the server, so no roles.
        if error.code != 404:
            raise
        roles = []
    return {
        "id": user["id"],
        "user_name": user.get("global_name") or user["username"],
        "preferred_username": user["username"],
        "email": user.get("email"),
        "email_verified": bool(user.get("verified")),
        "groups": roles,
    }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            status, body = 200, userinfo(self.headers.get("Authorization", ""))
        except urllib.error.HTTPError as error:
            status, body = (401 if error.code == 401 else 502), {"error": f"discord returned {error.code}"}
        except Exception as error:
            status, body = 502, {"error": type(error).__name__}
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


class Server(ThreadingHTTPServer):
    address_family = AF_INET6


if __name__ == "__main__":
    # Loopback only: Dex runs in the same pod.
    Server(("::1", 8081), Handler).serve_forever()
