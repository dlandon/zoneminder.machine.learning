# Set up some defaults
update zm.Config SET Value='/zm/cgi-bin/nph-zms' WHERE Name='ZM_PATH_ZMS';
update zm.Config SET Value='/usr/bin/avconv' WHERE Name='ZM_PATH_FFMPEG';
update zm.Config SET Value=1 WHERE Name='ZM_OPT_FFMPEG';
update zm.Config SET Value=1 WHERE Name='ZM_OPT_CAMBOZOLA';
update zm.Config SET Value='-r 30 -vcodec libx264 -threads 2 -b 2000k -minrate 800k -maxrate 5000k' WHERE Name='ZM_FFMPEG_OUTPUT_OPTIONS';
update zm.Config SET Value='mp4* mpg mpeg wmv asf avi mov swf 3gp**' WHERE Name='ZM_FFMPEG_FORMATS';
update zm.Config SET Value='/usr/sbin/ssmtp' WHERE Name='ZM_SSMTP_PATH';
update zm.Config SET Value=0 WHERE Name='ZM_RUN_AUDIT';
