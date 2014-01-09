setenv P4CONFIG .p4config
cd /home/ankitko/Perforce
xip initws -server xcoscmproxy:1686 -project ipv_regressions
cd /home/ankitko/Perforce/IP3_ankitko_ipv_regressions/DEV
xip getcore -core c_addsub_v11_0 -branch DEV
xip getcore -core $core -branch DEV
