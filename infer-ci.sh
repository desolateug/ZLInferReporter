set -e
set -o pipefail

xcodebuild -version

workspace_path=`pwd`
cd $workspace_path/Code

version=`git branch | awk '$1 == "*"{print $2}'`
date=`date +%F_%T`
output_dir=$workspace_path/${version}_$date
pre_dir=$workspace_path/$DIFF_VERSION
project_name=""

for file in `ls`
do
	if [[ $file = *.xcworkspace ]]; then
		project_name=${file%.*} 
		break
	fi
done

xcodebuild clean -workspace $project_name.xcworkspace -scheme $project_name -configuration $CONFIGURATION
xcodebuild -workspace $project_name.xcworkspace -scheme $project_name -configuration $CONFIGURATION COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_STYLE=Automatic | tee xcodebuild.log

export PATH=$PATH:/usr/bin/ruby:/usr/local/bin/infer
export LC_CTYPE=en_US.UTF-8
/usr/local/bin/xcpretty -r json-compilation-database -o compile_commands.json < xcodebuild.log > /dev/null
/usr/local/bin/infer run --compilation-database-escaped compile_commands.json --keep-going

zlinferreporter bugs-format infer-out/bugs.txt --support-types $SUPPORT_TYPES --pod-schemes $POD_SCHEMES

mkdir $output_dir

if [[ -n "${pre_dir}" ]] && [[ $DIFF_VERSION != $version ]] && [[ ! -d "${pre_dir}" ]]; then
	for dir in `ls $workspace_path`
	do
		if [[ $dir = ${DIFF_VERSION}* ]]; then
			pre_dir=$workspace_path/$dir
		fi
	done
fi

if [[ ! -d "${pre_dir}" ]]; then
	echo "no diff with $DIFF_VERSION"
else
	echo "diff with $DIFF_VERSION"
	/usr/local/bin/infer reportdiff --report-current infer-out/report.json --report-previous $pre_dir/report.json
	zlinferreporter report-format infer-out/differential/introduced.json --support-types $SUPPORT_TYPES --pod-schemes $POD_SCHEMES
	mv infer-out/differential $output_dir
fi

mv infer-out/bugs.txt $output_dir
mv infer-out/report.json $output_dir
mv infer-out/filtered-infer-out $output_dir

rm -r infer-out