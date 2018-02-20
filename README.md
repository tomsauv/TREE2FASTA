
TREE2FASTA allows for the interactive, flexible and rapid sorting of FASTA sequences from clades of interest with minimal user efforts via tree edits in the popular tree-viewer FigTree.

To run TREE2FASTA you need the FASTA file you use to build your exploratory tree, and the edited version of that tree saved from FigTree (edited for color and/or annotation).

![Screenshot](img4git.png)

See our FigTree tutorial [here](Tutorial.pdf)

# TREE2FASTA usage

**1) Navigate with terminal to the desired working directory**

cd   path_to_working_directory

Place TREE2FASTA.pl, the edited tree file and the FASTA file in this working directory (or indicate the paths to the location of the script and files in the command line). 

**2) Run TREE2FASTA as follows:**

perl   TREE2FASTA.pl   tre_file_name   fasta_file_name 

**Example command line with supplementary files provided**

perl   TREE2FASTA.pl   example_tree.tre   example_fasta.fas

To see command line usage for TREE2FASTA, type:

perl   TREE2FASTA.pl

# Input

**TREE file:**

Andrew Rambaut’s FigTree is required to edit exploratory trees as input for TREE2FASTA (see our [tutorial](Tutorial.pdf)).
FigTree is available at http://tree.bio.ed.ac.uk/software/figtree

**FASTA file:**

FASTA sequence names in the FASTA file should match those in the exploratory tree (newick string).   
We recommend using the RAxML tree-building program, which will preserve the sequence header format from FASTA input to Newick string output. Some support is available to correct character discrepancy for tree files saved from MEGA (presence/absence of underscore characters in sequence names). TREE2FASTA will print headers discrepancies to help troubleshooting.

# Perl version

TREE2FASTA.pl was written in Perl v5.24.0 with basic syntax and does not require the installation of specific modules to run
