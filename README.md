# Bad Apple Revit

## Commands to extract frames from video

```
ffmpeg -i input.mp4 -vf fps=1 out%d.png
```