#!/bin/sh
# 1-bit particle/dither look on a clean black background. Needs only ffmpeg.
#   ./dither.sh in.jpg out.png     -> still
#   ./dither.sh in.jpg out.gif     -> animated; per-frame noise reshuffles the dots so the grain shimmers
# The whole trick is CURVES: crush everything below the first knee to pure black,
# so the studio backdrop vanishes and only the marble dithers. Retune per source —
# a darker photo needs a lower knee, a brighter one higher.
# Knobs: CROP (w:h:x:y, cut off the plinth), H (subject height), PAD (w:h:x:y for a banner),
#        NOISE (shimmer strength), FPS, SECS.
set -e
CROP=${CROP:-1900:2980:480:390}
H=${H:-760}
CURVES=${CURVES:-0/0 0.45/0 0.62/0.55 0.8/0.95 1/1}
PAD=${PAD:-}
NOISE=${NOISE:-12}; FPS=${FPS:-10}; SECS=${SECS:-1.2}

[ -n "$PAD" ] && PADF="pad=$PAD:black," || PADF=""
case "$2" in
  *.gif|*.apng) IN="-loop 1 -framerate $FPS -t $SECS"; OUT="-loop 0"; MOTION="noise=alls=$NOISE:allf=t," ;;
  *)            IN=""; OUT=""; MOTION="" ;;
esac

# shellcheck disable=SC2086
ffmpeg -y -v error $IN -i "$1" -filter_complex \
  "[0:v]crop=$CROP,scale=-1:$H,${PADF}format=gray,${MOTION}curves=all='$CURVES',split[a][b];\
   [a]palettegen=max_colors=2:reserve_transparent=0[p];\
   [b][p]paletteuse=dither=floyd_steinberg" $OUT "$2"
echo "wrote $2"
