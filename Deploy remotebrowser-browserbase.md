- [x] Learn the changes
- [ ] deployment
	- [x] Modify its `deploy-fly.yml` to add a new Fly app `remotebrowser-browserbaseq
	- [x] Get the Browserbase API key from Keeper and use it
	- [x] Stick to one Fly machine since there's in-state memory in this Browserbase backend (https://github.com/remotebrowser/remotebrowser/pull/1413)
		- [x] fix fly token
	- [x] After it's working, create another `connect-browserbase` , i.e. our CoreLens connector utilizing the above Browserbase-powered Remote Browser.
	- [x] Add the above to the hourly test in our test manager.
	- [x] Fix test
	- [ ] 

## Result
- Deployed at Yuxi-yao org same as remoteborwser-daytona
- scale to 1 (add screenshot)
- https://github.com/remotebrowser/remotebrowser/pull/1418
- https://github.com/corelens-engineering/demos/pull/1181
- ![[Pasted image 20260727192806.png]]