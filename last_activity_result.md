- backstage  cdp.py:44 `client.get(f{base}/api/v1/browsers/{browser_id}")`
- remotebrowser router.py:290 `return await backend.get_browser(...)`
- daytona_browsers.py::209 `return await self._get_info(sandbox)`
- _get_info `"last_activity_timestamp": await self._get_last_activity(sandbox)`
				- _get_last_activity `await sandbox.process.exec(
                                 "cp /home/user/chrome-profile/Default/History /tmp/... && sqlite3 ..."
                               )