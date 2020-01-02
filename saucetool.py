#! /usr/bin/python

"""
This is a quick program to parse and report differences between installed RPMs on
two systems.  To use it, give the program the path to sosreports that are to be
compared:

    ./rpmdiff.py /path/to/sos1 /path/to/sos2 /path/to/sos3 [....]

Note:  These are paths to directories, not individual files!
"""

#TODO: There is no error handling...at all.

#################################################
# Imports
#################################################

import sys
import re
import argparse
from collections import defaultdict


#################################################
# Functions
#################################################

# Set up a factory
def tree():
    """
    Factory that creates a defaultdict that also uses this factory
    """
    return defaultdict(tree)


# Put a list into the tree, creating any keys that don't exist
def insert(tree, tokens):
    for t in tokens:
        tree = tree[t]


def rpm_name_decompose(s, unsplit):
    '''
    This will split the RPM (hopefully) into the 'name' component, the full version 
    info, and the release and arch info.  Result returned as a list.
    >>>> Note the outer parens, they are necessary to keep re.split from 
    consuming the separator.
    '''
    # This is a total work in progress, so let's just report whatever doesn't split
    #   for future study and refinement.
    result =  filter(None, re.split(r'-([\d\-.]+(?:git|svn|git[\w\d]+|cvs)?[\d\-.]+)(el\d_?\d?.*|(?:el\d_?\d?|rhel\d)?.x86_64|(?:el\d)?.noarch|.\(none\)|i386)', s))
    # If the length of the resulting list is 1, the name was not split.  Record it and
    #   do not add the RPM to the compare tree
    if len(result) == 1:
        unsplit.append(result)
        return None
    return result


def parse_rpms_to_tree(tree, rpmfile, hostname):
    """
    Fills a passed in dictionary, using RPM names split at each '-'.  Hostnames are
    put as leaf values
    """
    for line in rpmfile.readlines():
        # Send the RPM name to be split without the date
        rpm_tokens = rpm_name_decompose(line.split()[0], unsplit)
        # Append hostname before insertion
        try:
            rpm_tokens.append(hostname)
            # Add each token on the list to the tree
            insert(tree, rpm_tokens)
        # Here we only want to avoid a traceback for an unhandled RPM name.  We have
        #   already recorded the offending RPM in a list.
        except AttributeError:
            continue


# Options for argument parsing
def add_arguments(opts):
    """
    Function to handle the argument parsing and keep the code separate/readable
    """
    opts.add_argument('path', metavar='path', type=str,
                      action='append', nargs='*',
                      help='Path to sosreport directory')


#################################################
# Definitions
#################################################

#TODO:  Probably don't need all these but it's written and working, and if arbitrary numbers of sosreports are
#         handled the design will have to change anyway

rpm_compare_tree = tree()
hosts            = []
opts             = argparse.ArgumentParser()
unsplit          = []


#################################################
# Main
################################################

add_arguments(opts)
run_opts = opts.parse_args()

# Make sure we got at least 2 sosreports on the command line
if len(run_opts.path[0]) <= 1:
    print("\n\tOnly one path supplied, please specify a path to 2 sosreport directories.\n\n")
    sys.exit(1)


# Populate a list of hosts from the passed in sosreport directories and parse the
#  RPM data into the tree.  Paths are in run_opts.path[0] as a list.
#
# TODO: There is really no error checking, so if the files are missing just complain
#         as long as there are at least 2 valid hosts provided
for path in run_opts.path[0]:
    try:
        hn = open(path + '/hostname', 'r').read().strip() + '-' + \
                ''.join(open(path + '/date', 'r').read().strip()[4:19].replace(' ','-'))
        f  = open(path + '/installed-rpms', 'r') 
        hosts.append(hn)
        parse_rpms_to_tree(rpm_compare_tree, f, hn)
    except IOError:
        print("\n\tError attempting access to files in the following provided path:\n\t\t%s\n\tAttempting to continue...\n" 
                % (path))

# If we weren't able to read/parse more than one unique hostname we should stop
if len(set(hosts)) <= 1:
    print("\nERROR: Unable to parse enough hostnames, check the provided paths.")
    print ("\t2 unique sosreports are required to compare.\n")
    sys.exit(1)

# List out all the RPMs that could not be parsed by the regex
print("\nTotal number RPMs that the regex was unable to handle:\t%d" % len(unsplit) )
print("List of unparsed RPMs which were not compared:")
for rpm in unsplit:
    print("\t%s" % rpm[0])

print("\nNow listing all differences:\n")

output = ""
for rpm in rpm_compare_tree:
    flag = False
    output = rpm + '\n'
    for version in rpm_compare_tree[rpm]:
        for relarch in rpm_compare_tree[rpm][version]:
            # Is this RPM version on all hosts or not?
            if len(rpm_compare_tree[rpm][version][relarch]) != len(set(hosts)):
                flag = True
                output += "\t%s%s\n" % (version, relarch)
                for host in rpm_compare_tree[rpm][version][relarch]:
                    output += "\t\t%s\n" % host
    if flag:
        print output    

# The tree build can be visualized by uncommenting the following.
#import json
#print json.dumps(rpm_compare_tree, sort_keys=True, indent=2)
