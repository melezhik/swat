project=$1
url=$2


prove_flags=$3
prove_flags=${prove_flags:='-v'}
debug=${debug:=0}
ignore_http_err=${ignore_http_err:=0}
try_num=${try_num:=2}
curl_connect_timeout=${curl_connect_timeout:=5}
curl_max_time=${curl_max_time:=20}
head_bytes_show=${head_bytes_show:=400}
swat_ini_file=${swat_ini_file:='swat.ini'}

mkdir -p ~/.swat/.cache/$entity/

session_file=~/.swat/.cache/$entity/session


if [ \( -d $project  \) -a  \(  -n  "${url}" \)  ] ; then


    safe_project=`perl -MFile::Basename -e '$i=$ARGV[0]; s{\/$}[], chomp for $i; print $i' $project`

    mkdir -p $safe_project

    echo "try_num=$try_num" > $session_file
    echo "ignore_http_err=$ignore_http_err" >> $session_file
    echo "curl_params=''" >> $session_file

    test -f $safe_project/$swat_ini_file && source $safe_project/$swat_ini_file

    reports_dir=~/.swat/reports/$url/
    rm -rf $reports_dir
    mkdir -p $reports_dir

    for f in `find $safe_project/ -type f -name get.txt -o -name post.txt`; do

        test_dir=`perl -e '$sp=$ARGV[0]; s{\w+\.txt$}[] for $sp; chomp $sp; print $sp' $f`;

        test -f $session_file && source $session_file
        test -f $safe_project/$swat_ini_file && source $safe_project/$swat_ini_file
        test -f $test_dir/$swat_ini_file && source $test_dir/$swat_ini_file

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

    prove -m -r $prove_flags $reports_dir;

elif [ -n  "${url}"  ] ; then
    echo "project directory parameter is not set or not exists"
    echo "usage swat project URL"
    exit 1

elif [ -d $project ] ; then
    echo "url parameter is not set"
    echo "usage swat project URL"
else
    echo "usage swat project URL"
    exit 1
fi


