while :
do
  echo "Start server"
  luajit start.lua | tee -a logs/log_$(date +'%Y_%m_%d').txt
  sleep 1
done
