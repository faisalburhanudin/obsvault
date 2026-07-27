- [x] Learn the changes
- [ ] deployment
	- [x] Modify its `deploy-fly.yml` to add a new Fly app `remotebrowser-browserbaseq
	- [x] Get the Browserbase API key from Keeper and use it
	- [x] Stick to one Fly machine since there's in-state memory in this Browserbase backend (https://github.com/remotebrowser/remotebrowser/pull/1413)
		- [ ] fix fly token
	- [ ] After it's working, create another `connect-browserbase` , i.e. our CoreLens connector utilizing the above Browserbase-powered Remote Browser.
	- [ ] Add the above to the hourly test in our test manager.

## Result
- Deployed at Yuxi-yao org same as remoteborwser-daytona
- 