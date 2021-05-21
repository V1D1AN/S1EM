echo "##########################################"
echo "######         UPGRADING S1EM      #######"
echo "##########################################"
echo  
git stash save "pre-upgrade S1EM configuration changes"
git pull --rebase
docker-compose pull
git stash pop
echo 
echo
echo "if you see Merge conflict messages, resolve the conflicts with your favorite text editor"
echo
read -p "continue after resolving merge conflict ? (Y/N)" confirm
case $confirm in 
        [yY][eE][sS]|[yY])
        docker-compose up -d
        ;;
        [nN][oO]|[nN])
        ;; *)
        echo "Invalid input ..."
     exit 1
     ;;
esac


echo "##########################################"
echo "######  UPGRADING OF S1EM COMPLETE  ######"
echo "##########################################"

