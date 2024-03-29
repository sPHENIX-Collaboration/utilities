import sys
import re
import pprint
import argparse

print (f"Python env check: {sys.executable} Version {sys.version} with paths {sys.path}")

#%% input

input_files = ["Fun4All_G4_sPHENIX.log"]
output_csv = "Fun4All_G4_sPHENIX.csv"

search_items = {
    'Time (s)': '\sUser time \(seconds\):\s*([-+]?[0-9]*\.?[0-9]*)$',
    'Memory (kB)': '\sMaximum resident set size \(kbytes\):\s*([-+]?[0-9]*\.?[0-9]*)$',
    }

search_dynamic_items = {
    'Module accumulated time (ms)': '([A-Za-z0-9_]+): accumulated time \(ms\):\s*([-+]?[0-9]*\.?[0-9]*)',
    'Module per event time (ms)': '([A-Za-z0-9_]+): per event time \(ms\):\s*([-+]?[0-9]*\.?[0-9]*)',
    }


parser = argparse.ArgumentParser(description='Parse log file into data CSV.')
parser.add_argument('--input_files',type=str, nargs='+', 
                    help='input log file', required=True)
parser.add_argument('--output_csv', type=str,
                    help='output csv\'s name prefix', required=True)
parser.add_argument('--output_max_col', type=int, default=8,
                    help='Max col. count for the result CSV', required=False)

args = parser.parse_args()
input_files = args.input_files
output_csv = args.output_csv
output_max_col = args.output_max_col

print("Input arguments: ",args)

#%% init 

search_compile = {}
search_dynamic_compile = {}

for label, exp in search_items.items():
    print(f"Search for {label} with regular expression [{exp}]")
    search_compile[label] = re.compile(exp)
for label, exp in search_dynamic_items.items():
    print(f"Dynamic search for {label} with regular expression [{exp}]")
    search_dynamic_compile[label] = re.compile(exp)

search_results = {}
search_dynamic_results = {}

for label in search_compile.keys():
    search_results[label] = {} # dictionary of file -> value
search_results['STDOUT Linecount'] = {}
for label in search_dynamic_items.keys():
    search_dynamic_results[label] = {} # dictionary of file -> value

#%% processing


for input_file in input_files:
    print (f"Processing {input_file}")

    with open(input_file, 'r') as file1:

        Lines = file1.readlines()
        
        count = 0
        # Strips the newline character
        for line in Lines:
            count += 1
            # print("Line {}: {}".format(count, line.strip()))
            
            for label,reexp in search_compile.items():

                match = reexp.search(line)

                if match:
                    # print (f"{line.strip()} -> { match.group(1) }")
                    search_results[label][input_file] = float(match[1])

            for label,reexp in search_dynamic_compile.items():

                match = reexp.search(line)

                if match:
                    # print (f"{line.strip()} -> { match.groups()}")

                    if match[1] not in search_dynamic_results[label].keys():
                        search_dynamic_results[label][match[1]] = []

                    search_dynamic_results[label][match[1]].append( float(match[2]) )

        search_results['STDOUT Linecount'][input_file] = count
        file1.close()

# %% results

# pprint.pprint(search_results);

# pprint.pprint(search_dynamic_results);

#%% to csv

for label,result_dict in search_results.items():

    label_filename = label.replace(" ", "_")
    csv_name = f"{output_csv}_{label_filename}.csv"
    print (f"Output results for {label} to {csv_name}")

    with open(csv_name, 'w') as f:

        value_list = list(result_dict.values())

        summary_dict = {}

        summary_dict[label] = str(sum(value_list) / len(value_list))
        summary_dict['count'] = str(len(value_list))
        summary_dict['min'] = str(min(value_list))
        summary_dict['max'] = str(max(value_list))

        f.write("{}\n".format(",\t".join(summary_dict.keys())))
        f.write("{}\n".format(",\t".join(summary_dict.values())))
        f.close()
    with open(csv_name, 'r') as f:
        print(f.read())


for label,result_dict in search_dynamic_results.items():

    label_filename = label.replace(" ", "_")
    csv_name = f"{output_csv}_{label_filename}.csv"
    print (f"Output results for {label} to {csv_name}")


    with open(csv_name, 'w') as f:

        module_dict = {}
        module_list = []
        value_list = []

        for module_name,result_values in result_dict.items():
            module_dict[module_name] = sum(result_values) / len(result_values)

        module_dict = dict(sorted(module_dict.items(), key=lambda item: item[1], reverse=True))

        count = 0
        for key,value in module_dict.items():
            module_list.append(key)
            value_list.append(str(value))
            
            count = count +1
            if count >= output_max_col: 
                break

        f.write("{}\n".format(",\t".join(module_list)))
        f.write("{}\n".format(",\t".join(value_list)))
        f.close()

    with open(csv_name, 'r') as f:
        print(f.read())
    print(f"--- {len(module_list)} Entries ---")
    

# %%
