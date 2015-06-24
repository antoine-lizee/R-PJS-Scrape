
command="getAndParse.R"
job="*/5 * * * * Rscript --no-init-file /media/FD/PERSO/phantomJS/getAndParse.R >> /media/FD/PERSO/phantomJS/getAndParse.log"
crontab -l | fgrep -i -v "$command" | { cat; echo "$job"; } | crontab -l

command="cleanZombies.R"
job="4 * * * * Rscript --vanilla /media/FD/PERSO/phantomJS/cleanZombies.R >> /media/FD/PERSO/phantomJS/getAndParse.log"
crontab -l | fgrep -i -v "$command" | { cat; echo "$job"; } | crontab -l

