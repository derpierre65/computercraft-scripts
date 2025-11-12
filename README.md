To download any script use this code after run `lua` in your terminal:

```lua
shell.run("rm download"); local file = fs.open('download', 'w'); file.write(http.get('https://raw.githubusercontent.com/derpierre65/computercraft-scripts/main/download.lua').readAll()); file.close(); os.reboot()
```

`download: No matching files` for fresh computers/turtles is not an issue.

You can run the download script directly from your computer or copy it to a disk and run it from there.

## Not supported HTTPS URLs

Older ComputerCraft versions do not support HTTP**S** URLs. You can create a `http_prefix` file in the root of your disk to define a proxy url.

If you have a proxy server that expects an url like `http://my-proxy-url.test/?url=https://your-https-url.test/test.lua` you can create a `http_prefix` file with `http://my-proxy-url.test/?url=`. Every http request in my scripts will be prefixed with this string.