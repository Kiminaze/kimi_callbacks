
## Support

If you require any form of support after acquiring this resource, the right place to ask is our 
Discord Server: https://discord.kiminaze.de

Make sure to react to the initial message with the tick and your language to get access to all 
the different channels.

Please do not contact anyone directly unless you have a really specific request that does not have 
a place in the server.


## What exactly is "kimi_callbacks" and what can you do with it?

"kimi_callbacks" is a LUA script for FiveM that allows you to create custom server and client 
callbacks in an easy manner. This script does nothing by itself and needs to be used via exports 
from other resources.

I decided to create this script as a base for my other scripts and I felt like the others out there 
didn't really exactly suit my needs.


## Features

- Clients can request data from the server.
- Server can request data from a client.
- Includes configurable timeouts for requests that take too long.
- Any amount of values can be returned / send.
- Uses exports for all functions.
- Examples explaining all you need to know.
- Compatible with everything.


## Performance

- This script does not really use any performance, unless a lot of request are running in parallel.
- Idle: both client and server: 0.00ms
- 100 parallel server callbacks (for the splitsecond they are active at the same time and chances 
  are pretty much 0 to get even 5 at the same time):
  - client side: ~0.30ms
  - server side: ~0.00-0.01ms


## Installation

1. Download the script from [Github](https://github.com/Kiminaze/kimi_callbacks/releases).
2. Extract the folder into your resources folder.
3. Make sure the folder name of the script is `kimi_callbacks`
4. Go into your server.cfg and put the line `ensure kimi_callbacks` as high up as possible.


## Patchnotes

### Update v1.3.0
- Added error message display directly into the callbacks. Certain newer server versions should now 
  see the messages in both client and server console!

### Update v1.2.0
- Added asynchronous callbacks.
- Added additional error checking.
- Added additional detailed error messages.
- An error in a callback now immediately throws an error instead of waiting for the timeout.
- Reformatted everything.
- Added wiki to Github repo.
- Added releases.
- Updated license.

### Hotfix v1.1.2
- Added an additional error check.

### Hotfix v1.1.1
- Fixed error when registering a callback.

### Update v1.1
- Added additional error checks to show user friendly error messages.
- Exports now defined directly inside the script instead of the fxmanifest file.
