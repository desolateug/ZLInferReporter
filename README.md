zlinferreporter is used to format infer output files(xxx.json or bugs.txt). It's easy to filter out bugs of the specified type. You can also specify whitelist(class prefixes or keywords) to ignore the third-party libs.

## Usage:

zlinferreporter COMMAND FILE  
  
$ zlinferreporter bugs-format bugs.txt --support-types ASSIGN_POINTER_WARNING,MEMORY_LEAK --pod-schemes zl  
OR  
$ zlinferreporter report-format introduced.json --support-types ASSIGN_POINTER_WARNING,MEMORY_LEAK --pod-schemes zl

## Commands:

+ bugs-format
+ report-format

## Options:

+ --support-types type1,type2
+ --pod-schemes scheme1,scheme2

You can also use zlinferreporter.config to specify options.  

## Outputs:
Outputs will be generated in FILE's directory.
