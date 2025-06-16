
# 查詢當前用戶的權限
select current_user();

show grants for current_user();

grant  select,insert,update,delete,create,drop,reload,shutdown,process,file,references,index,alter,show databases,super,create temporary tables,lock tables,execute,replication slave,replication client,create view,show view,create routine,alter routine,create user,event,trigger,create tablespace,create role,drop role on *.* to `eapdbsa`@`%`

grant application_password_admin,audit_abort_exempt,audit_admin,authentication_policy_admin,backup_admin,binlog_admin,binlog_encryption_admin,clone_admin,connection_admin,encryption_key_admin,flush_optimizer_costs,flush_status,flush_tables,flush_user_resources,group_replication_admin,group_replication_stream,innnodb_redo_log_archive,innodb_redo_log_enalbe,passwordless_user_admin,persist_ro_variables_admin,replication_applier,replication_slave_admin,resource_group_admin,resource_group_user,role_admin,service_connection_admin,session_variables_admin,set_user_id,show_routine,system_user,system_variables_admin,table_encryption_admin,xa_recover_admin on *.* to `eapdbsa`@`%`


###
# 我問一下，我用 show grants for current_user(); 查詢出來當前用戶的權限，這些都是幹啥的，我只知道增刪查改，其他的你可以給我解析一下嗎
grant  select,insert,update,delete,create,drop,reload,shutdown,process,file,references,index,alter,show databases,super,create temporary tables,lock tables,execute,replication slave,replication client,create view,show view,create routine,alter routine,create user,event,trigger,create tablespace,create role,drop role on *.* to `test`@`%`

grant application_password_admin,audit_abort_exempt,audit_admin,authentication_policy_admin,backup_admin,binlog_admin,binlog_encryption_admin,clone_admin,connection_admin,encryption_key_admin,flush_optimizer_costs,flush_status,flush_tables,flush_user_resources,group_replication_admin,group_replication_stream,innnodb_redo_log_archive,innodb_redo_log_enalbe,passwordless_user_admin,persist_ro_variables_admin,replication_applier,replication_slave_admin,resource_group_admin,resource_group_user,role_admin,service_connection_admin,session_variables_admin,set_user_id,show_routine,system_user,system_variables_admin,table_encryption_admin,xa_recover_admin on *.* to `test`@`%`


show processlist;

SHOW SLAVE STATUS;

