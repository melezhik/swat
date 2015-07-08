entity=$1


echo
echo 'fetch project metadata ...'
echo

prove_flags=$2
prove_flags=${prove_flags:='-v'}
resolver_ip=${resolver_ip:='10.147.136.30:8081'}
debug=${debug:=0}
ignore_http_err=${ignore_http_err:=0}
try_num=${try_num:=2}
resolver_retry_num=${resolver_retry_num:=0}
clear_cache=${clear_cache:=0}
curl_connect_timeout=${curl_connect_timeout:=5}
curl_max_time=${curl_max_time:=20}
head_bytes_show=${head_bytes_show:=400}
port=${port:='8080'}
use_domain_names=${use_domain_names:='0'}

mkdir -p ~/.swat/.cache/$entity/

tmp_file=~/.swat/.cache/$entity/node.cache
test -f $tmp_file && rm -rf $tmp_file

node_file=~/.swat/.cache/$entity/node.txt
session_file=~/.swat/.cache/$entity/session

if [ "$clear_cache" -eq '1' ]; then
    test -f $node_file && rm -rf $node_file
    curl --connect-timeout 20 -m 200  --noproxy $resolver_ip -s -d "resolver_retry_num=${resolver_retry_num}" -X POST -f $resolver_ip/autotest/$entity -o $tmp_file

fi


if test -f $node_file ; then

    cached=1
    project=`perl -n -e '/project:\s+(\S+)/ and print $1' $node_file`
    ip_addr=`perl -n -e '/ipaddress:\s+(\S+)/ and print $1' $node_file`
    nodename=`perl -n -e '/name:\s+(\S+)/ and print $1' $node_file`
    deploy_env=`perl -n -e '/deploy_env:\s+(\S+)/ and print $1' $node_file`
    fqdn=${fqdn:=`perl -n -e '/fqdn:\s+(\S+)/ and print $1' $node_file`}

else

    curl --noproxy $resolver_ip -s -Lf $resolver_ip/autotest/resolver/$entity -o $tmp_file || \
    curl --connect-timeout 20 -m 200  --noproxy $resolver_ip -s -d "resolver_retry_num=${resolver_retry_num}" -X POST -f $resolver_ip/autotest/$entity -o $tmp_file

    project=`perl -n -e '/project:\s+(\S+)/ and print $1' $tmp_file`
    nodename=`perl -n -e '/name:\s+(\S+)/ and print $1' $tmp_file`
    ip_addr=`perl -n -e '/ipaddress:\s+(\S+)/ and print $1' $tmp_file`
    deploy_env=`perl -n -e '/deploy_env:\s+(\S+)/ and print $1' $tmp_file`
    fqdn=${fqdn:=`perl -n -e '/fqdn:\s+(\S+)/ and print $1' $tmp_file`}

    cached=0



fi



if [ $project ]; then


    # update cache
    if [ "$cached" -eq '0' ]; then
        cp $tmp_file $node_file
    fi

    deploy_env=${deploy_env:='?'}

    safe_project=`perl -MFile::Basename -e '$a=fileparse($ARGV[0]); chomp $a; print $a' $project`

    mkdir -p $safe_project


    echo "try_num=$try_num" > $session_file
    echo "ignore_http_err=$ignore_http_err" >> $session_file
    echo "curl_params=''" >> $session_file

    test -f $safe_project/project.ini && source $safe_project/project.ini


    if [ "$use_domain_names" -eq '1' ]; then
        url=$fqdn:$port
    else
        url=$ip_addr:$port
    fi

    reports_dir=~/.swat/reports/$ip_addr/
    rm -rf $reports_dir
    mkdir -p $reports_dir


    perl -Mswat -e print_fmt \
    'time' `date +'%Y-%m-%d...%R:%S'` \
     entity $entity \
     'reports directory' $reports_dir \
     port $port \
    'fqdn' $fqdn \
    'ip address' $ip_addr \
     url $url \
    'use domain names' $use_domain_names \
    'project safe path' $safe_project \
     'node name' $nodename \
    'deploy env' $deploy_env \
    'prove flags' $prove_flags \
    'debug' $debug \
    'ignore http errors' $ignore_http_err \
    'http try number'  $try_num \
    'resolver retry number'  $resolver_retry_num \
    'clear cache' $clear_cache \
     'cached' $cached \
    'node file'   $node_file \
    'resolver ip'  $resolver_ip \
    'curl connect timeout'  $curl_connect_timeout \
    'curl max time'  $curl_max_time \
    'head bytes show' $head_bytes_show

    for f in `find $safe_project/ -type f -name get.txt -o -name post.txt`; do

        test_dir=`perl -e '$sp=$ARGV[0]; s{\w+\.txt$}[] for $sp; chomp $sp; print $sp' $f`;

        test -f $session_file && source $session_file
        test -f $safe_project/project.ini && source $safe_project/project.ini
        test -f $test_dir/project.ini && source $test_dir/project.ini

        path=`perl -e '$sp=$ARGV[0]; $p=$ARGV[1]; s{^$sp}[], s{\w+\.txt}[], s{/$}[] for $p; chomp $p; $p = "/"  unless $p; print $p' $safe_project $f`;
        mkdir -p "${reports_dir}/${path}";

        http_meth=`perl -e '$p=$ARGV[0]; $p=~/(\w+)\.txt$/ and print uc($1)' $f`;

        if [ "$ignore_http_err" -eq '1' ]; then
            curl_cmd="curl -X $http_meth --noproxy $url ${curl_params} -k  --connect-timeout $curl_connect_timeout -m $curl_max_time -D - -L  --stderr - http://$url$path"
        else
            curl_cmd="curl -X $http_meth --noproxy $url ${curl_params} -k -f --connect-timeout $curl_connect_timeout -m $curl_max_time -D - -L  --stderr - http://$url$path"
        fi

        tfile="${reports_dir}/${path}/00.t"

        echo 'BEGIN { push @INC, q{'`pwd`'}; }'  > $tfile
        echo >> $tfile

        echo "use Test::More q{no_plan};"  >> $tfile
        echo "use constant deploy_env => q{$deploy_env};"  >> $tfile
        echo $\content_file = q{"${reports_dir}${path}/content};"  >> $tfile
        echo $\path = q{"${path}};"  >> $tfile
        echo $\http_meth = q{"${http_meth}};"  >> $tfile
        echo $\url = q{"${url}};"  >> $tfile
        echo $\debug = $debug';'  >> $tfile
        echo $\ignore_http_err = $ignore_http_err';'  >> $tfile
        echo $\head_bytes_show = $head_bytes_show';'  >> $tfile
        echo $\try_num = $try_num';'  >> $tfile
        echo $\curl_cmd = q{"${curl_cmd}};"  >> $tfile
        echo >> $tfile

        echo "require swat;"  >> $tfile
        echo >> $tfile

        echo "SKIP: {" >> $tfile
        echo -e "\tgenerate_asserts(q{$f})" >> $tfile;
        echo >> $tfile
        echo "}" >> $tfile

    done;

    echo
    echo 'running tests ...'
    echo

    prove -m -r $prove_flags $reports_dir;
else
    echo "cannot find project for $entity"
    test -e $tmp_file && cat $tmp_file
    exit 1
fi


