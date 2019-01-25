#!/bin/bash

#do some configure script

info 'add mysql service start.'
	configure_bin $EXEC_DIR_ASSEMBLE_BIN_VERSION'/service/mysqld' '/etc/init.d/mysqld'
	chkconfig --add mysqld
	chkconfig --level 3 mysqld on
	info "`chkconfig --list | grep mysqld`"
info 'add mysql service successfully.'
info 'start mysql.'
    create_dir $INSTALL_DIR_LOG_BIN
    touch $INSTALL_DIR_LOG_BIN/mysql.err.log
    chown $ENV_USER:$ENV_GROUP $INSTALL_DIR_LOG_BIN/mysql.err.log
	cd $LN_DIR_MYSQL
	rm ./my.cnf -rf
	scripts/mysql_install_db --user=$ENV_USER
	bin/mysqld_safe $BIN_START_PARAM &
info 'mysql started.'
info 'configure mysql start.'
    read -p 'input root password:' PWD 
    $LN_DIR_MYSQL/bin/mysql -h127.0.0.1 -uroot --port=$BIN_PORT -e "grant all privileges on *.* to root@'%' identified by '$PWD'"
    $LN_DIR_MYSQL/bin/mysql -h127.0.0.1 -uroot --port=$BIN_PORT -e "grant all privileges on *.* to root@'localhost' identified by '$PWD'"
info 'configure mysql successfully.'