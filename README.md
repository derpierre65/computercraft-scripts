To download any script use this code after run `lua` in your terminal:

```lua
shell.run("rm download"); local file = fs.open('download', 'w'); file.write(http.get('https://raw.githubusercontent.com/derpierre65/computercraft-scripts/main/download.lua').readAll()); file.close(); exit()
```