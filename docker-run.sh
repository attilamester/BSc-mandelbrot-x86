docker run --rm -it \
    -e DISPLAY="unix${DISPLAY:-:0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    attilamester/mandelbrot-x86:latest
