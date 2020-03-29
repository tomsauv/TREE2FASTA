#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

#### Command line arguments

my $number_args;
$number_args=$#ARGV+1;
if ($number_args !=2){
	print "\nUsage:";  	
	print "\n--------------------------------------------","\n";
	print "TREE2FASTA.pl tree_file_name fasta_file_name","\n";
	print "--------------------------------------------","\n";
	print "\nFor example:";
	print "\n---------------------------------------------------","\n";
	print "TREE2FASTA.pl example_tree.tre example_fasta.fas","\n";
	print "---------------------------------------------------","\n\n";
	exit;
}

my $treefile=$ARGV[0];
my $fastafile=$ARGV[1];


print "\nProvided tree file: '$treefile'","\n";
print "Provided fasta file: '$fastafile'","\n";

mkdir "Temp"; # Make folders where the different files will be printed
mkdir "lists_miscellaneous";

#### Sanitize file for PC/MAC compatibility

print "\nSanitizing files\n";

#### Sanitize fasta

my $fastafilesan="Temp/fasta.san";

open (FASTASCAN, ">:encoding(UTF-8)", $fastafilesan) or die "Cannot open the FASTASCAN:$!\n";
binmode(FASTASCAN);

open(INFILE_fasta, "<:encoding(UTF-8)", $fastafile) or die "Cannot open the INFILE_fasta:$!\n";
binmode(INFILE_fasta);

while (<INFILE_fasta>) {
    s/\x0D\x0A/\x0A/g;
    s/ /_/g;	# replace all spaces by underscores
    print FASTASCAN $_;
}

close FASTASCAN;
close INFILE_fasta;

#### Check first line of fasta file for '>'

open(INFILE_fasta, "<:encoding(UTF-8)", $fastafile) or die "Cannot open the INFILE_fasta:$!\n";
open (FASTASCAN,"<:encoding(UTF-8)", $fastafilesan) or die "Cannot open the FASTASCAN:$!\n";
my $first_fasta_line=<FASTASCAN>;
if ($first_fasta_line=~/^(.).+/ && $1 ne '>'){
    print "Check example fasta file format or check command line order","\n";
    exit;
}

close FASTASCAN;
close INFILE_fasta;

#### Sanitize tree

my $treefilesan="Temp/tree.san";

open (TREESAN,">:encoding(UTF-8)",$treefilesan) or die "Cannot open the TREESAN:$!\n";
binmode(TREESAN);

open(INFILE_tree, "<:encoding(UTF-8)", $treefile) or die "Cannot open the INFILE_tree:$!\n";
binmode(INFILE_tree);

while (<INFILE_tree>) {
    s/\x0D\x0A/\x0A/g;
    s/ /_/g;	# replace all spaces by underscores
    print TREESAN $_;
}

close TREESAN;
close INFILE_tree;

#### Check tree file for '#NEXUS' line

open(INFILE_tree, "<:encoding(UTF-8)", $treefile) or die "Cannot open the INFILE_tree:$!\n";
open (TREESAN,"<:encoding(UTF-8)", $treefilesan) or die "Cannot open the TREESAN:$!\n";
my $first_tree_line=<INFILE_tree>;
if ($first_tree_line=~/(.+)/ && $1 ne '#NEXUS'){
    print "Check example tree file format or check command line order","\n";
    exit;
}

close TREESAN;
close INFILE_tree;

print "\nOpening and parsing tree file.....";

#### Open edited tree file containing labels with color and annotation information

open (TREESAN,'<', $treefilesan) or die "Cannot open the TREESAN:$!\n";

my $Parsed_tree_file="Temp/Parsed_tree_file.txt";
open (PARSEDTREEFILE,">:encoding(UTF-8)",$Parsed_tree_file) or die "Cannot open the PARSEDTREEFILE:$!\n";

#### Clean up the tree file: keep line with color and/or annotation info and remove few quotes ('') introduced by figtree 
#### Depending on the order in which color or annotation is edited first on the tree, appended information to taxa labels changes order (i.e. whether '!name' and '!color' comes first on the line)
#### In some case, a label may also be colored and have no annotation, and vice versa, so parsing needs to take all these possibilities into account
#### This step also checks if users named clades or tips as NONAME, which would conflict with tree2fasta flow; the script also exits if NONAME is found in user annotation

my $j=0;
while (my $line3=<TREESAN>) {
	chomp $line3;
	if ($line3=~/\t'(.+)'\[&!color=#(.+),!name="(.+)"\]/ && $3 eq 'NONAME'){  # This cause script exit if 'NONAME' is found to avoid conflicts
	print "\nPlease do not use 'NONAME' as annotation","\n";
	print "Edit your annotations and rerun TREE2FASTA","\n";
	exit;
	}
	elsif ($line3=~/\t(.+)\[&!color=#(.+),!name="(.+)"\]/&& $3 eq 'NONAME'){  # This cause script exit if 'NONAME' is found to avoid conflicts
	print "\nPlease do not use 'NONAME' as annotation","\n";
	print "Edit your annotations and rerun TREE2FASTA","\n";
	exit;
	}
	elsif ($line3=~/\t'(.+)'\[&!name="(.+)",!color=#(.+)\]/&& $2 eq 'NONAME'){  # This cause script exit if 'NONAME' is found to avoid conflicts
	print "\nPlease do not use 'NONAME' as annotation","\n";
	print "Edit your annotations and rerun TREE2FASTA","\n";
	exit;	
	}
	elsif ($line3=~/\t(.+)\[&!name="(.+)",!color=#(.+)\]/&& $2 eq 'NONAME'){ # This cause script exit if 'NONAME' is found to avoid conflicts
        print "\nPlease do not use 'NONAME' as annotation","\n";
	print "Edit your annotations and rerun TREE2FASTA","\n";
	exit;
	}
	elsif ($line3=~/\t'(.+)'\[&!name="(.+)"\]/&& $2 eq 'NONAME'){ # This cause script exit if 'NONAME' is found to avoid conflicts
        print "\nPlease do not use 'NONAME' as annotation","\n";
	print "Edit your annotations and rerun TREE2FASTA","\n";
	exit;
	}
	elsif ($line3=~/\t(.+)\[&!name="(.+)"\]/&& $2 eq 'NONAME'){ # This cause script exit if 'NONAME' is found to avoid conflicts
        print "\nPlease do not use 'NONAME' as annotation","\n";
	print "Edit your annotations and rerun TREE2FASTA","\n";
	exit;
	}
    elsif ($line3=~/\t.+;/){	# This is a condition to remove line starting with a tab and finishing by semicolon, to avoid pushing those lines in the blank_labels array below
    }
	elsif ($line3=~/\t'(.+)'\[&!color=#(.+),!name="(.+)"\]/){
	print PARSEDTREEFILE "\>","$1","\t","$2","_","$3","\n";
	$j++;
	}
	elsif ($line3=~/\t(.+)\[&!color=#(.+),!name="(.+)"\]/){
        print PARSEDTREEFILE "\>","$1","\t","$2","_","$3","\n";
	$j++;
	}
	elsif ($line3=~/\t'(.+)'\[&!name="(.+)",!color=#(.+)\]/){
	print PARSEDTREEFILE "\>","$1","\t","$3","_","$2","\n";
	$j++;	
	}
	elsif ($line3=~/\t(.+)\[&!name="(.+)",!color=#(.+)\]/){
        print PARSEDTREEFILE "\>","$1","\t","$3","_","$2","\n";
	$j++;
	}
	elsif ($line3=~/\t'(.+)'\[&!color=#(.+)\]/){
        print PARSEDTREEFILE "\>","$1","\t","$2","_","NONAME","\n";
	$j++;
	}
	elsif ($line3=~/\t(.+)\[&!color=#(.+)\]/){
        print PARSEDTREEFILE "\>","$1","\t","$2","_","NONAME","\n";
	$j++;
	}
	elsif ($line3=~/\t'(.+)'\[&!name="(.+)"\]/){
        print PARSEDTREEFILE "\>","$1","\t","NOCOLR","_","$2","\n";
	$j++;
	}
	elsif ($line3=~/\t(.+)\[&!name="(.+)"\]/){
        print PARSEDTREEFILE "\>","$1","\t","NOCOLR","_","$2","\n";
	$j++;
	}
	elsif ($line3=~/\ttaxlabels/) {				# This gets rid of the 'taxlabels' line to avoid pushing it in the blank_labels array as well
	}
	elsif ($line3=~/\t'(.+)'/) {				# This gets labels with no info appended (i.e. no color & no annotation)
	print PARSEDTREEFILE "\>","$1","\t","NOCOLR","_","NONAME","\n";
	$j++;
	}	
	elsif ($line3=~/\t(.+)/) {				# This also gets labels with no info appended
	print PARSEDTREEFILE "\>","$1","\t","NOCOLR","_","NONAME","\n";
	$j++;
	}	
}

print "$j taxa labels found","\n";
close TREESAN;
close PARSEDTREEFILE;

print "Opening and formatting fasta file...";

#### Tabulate fasta file

open (FASTASCAN,'<',$fastafilesan) or die "Cannot open the FASTASCAN:$!\n";

my $Tabulated_fasta="Temp/Tabulated_fasta.txt";
open (TABULATEDFASTA,">:encoding(UTF-8)",$Tabulated_fasta) or die "Cannot open the TABULATEDFASTA:$!\n";

my $i=0;
while (my $line1=<FASTASCAN>){
	chomp $line1;
	if ($line1=~/>(.+)/){ 
		print TABULATEDFASTA "\n\>","$1","\t";
		$i++; 
	}
	else {
	print TABULATEDFASTA $line1;
	}
}
print "$i sequences found","\n";
close FASTASCAN;
close TABULATEDFASTA;

#### Starting QC for concordance of tree and fasta labels and any duplicates

open (PARSEDTREEFILE,"<:encoding(UTF-8)", $Parsed_tree_file) or die "Cannot open the PARSEDTREEFILE:$!\n";
my $All_tree_labels="Temp/All_tree_labels.txt";
open (ALLTREELABELS,">:encoding(UTF-8)", $All_tree_labels) or die "Cannot open the ALLTREELABELS:$!\n";

while (my $line_QC1=<PARSEDTREEFILE>) {
	chomp $line_QC1;
	if ($line_QC1=~/>(.+)\t(.+)/){
	print ALLTREELABELS "\>","$1","\n";
	}
}

close PARSEDTREEFILE;
close ALLTREELABELS;


open (TABULATEDFASTA,"<:encoding(UTF-8)", $Tabulated_fasta) or die "Cannot open the TABULATEDFASTA:$!\n";
my $All_fasta_labels="Temp/All_fasta_labels.txt";
open (ALLFASTALABELS,">:encoding(UTF-8)", $All_fasta_labels) or die "Cannot open the ALLFASTALABELS:$!\n";

while (my $line_QC2=<TABULATEDFASTA>) {
	chomp $line_QC2;
	if ($line_QC2=~/>(.+)\t(.+)/){
	print ALLFASTALABELS "\>","$1","\n";
	}
}

close TABULATEDFASTA;
close ALLFASTALABELS;
 

my @tree_labels;
open (ALLTREELABELS,"<:encoding(UTF-8)", $All_tree_labels) or die "Cannot open the ALLTREELABELS:$!\n";	
while (my $line_QC3=<ALLTREELABELS>) {	
	chomp $line_QC3;
	push (@tree_labels, $line_QC3);
	}

close ALLTREELABELS;


my @fasta_labels;	
open (ALLFASTALABELS,"<:encoding(UTF-8)", $All_fasta_labels) or die "Cannot open the ALLFASTALABELS:$!\n";	
while (my $line_QC4=<ALLFASTALABELS>) {	
	chomp $line_QC4;
	push (@fasta_labels, $line_QC4);
	}

close ALLFASTALABELS;

my %hash1; #for tree file labels
my %hash2; #for fasta file labels

foreach my $element1 (@tree_labels){
    $hash1{$element1}++;
}
foreach my $element2 (@fasta_labels){
    $hash2{$element2}++;
}

#### Checking for duplicates

print "\nChecking labels for duplicates...";

my $Labels_duplicate_check_in_tree="Temp/Labels_duplicate_check_in_tree.txt";
my $Labels_duplicate_check_in_fasta="Temp/Labels_duplicate_check_in_fasta.txt";
open (LABELSDUPLICATECHECKINTREE,">:encoding(UTF-8)",$Labels_duplicate_check_in_tree) or die "Cannot open the LABELSDUPLICATECHECKINTREE:$!\n";
open (LABELSDUPLICATECHECKINFASTA,">:encoding(UTF-8)",$Labels_duplicate_check_in_fasta) or die "Cannot open the LABELSDUPLICATECHECKINFASTA:$!\n";

foreach my $element1_key(keys %hash1){
	print LABELSDUPLICATECHECKINTREE $element1_key,"\t",$hash1{$element1_key},"\n";
}
foreach my $element2_key(keys %hash2){
	print LABELSDUPLICATECHECKINFASTA $element2_key,"\t",$hash2{$element2_key},"\n";
}

close LABELSDUPLICATECHECKINTREE;
close LABELSDUPLICATECHECKINFASTA;

my $x=0;
my $duplicatefasta="seq_duplicate_in_fasta.txt";

open (LABELSDUPLICATECHECKINFASTA,"<:encoding(UTF-8)", $Labels_duplicate_check_in_fasta) or die "Cannot open the LABELSDUPLICATECHECKINFASTA:$!\n";	
while (my $line_QC7=<LABELSDUPLICATECHECKINFASTA>) {
	chomp $line_QC7;
	if ($line_QC7=~/>(.+)\t(.+)/ && $2>=2){
	$x++;
    open (DUPLICATEFASTA,">:encoding(UTF-8)",$duplicatefasta) or die "Cannot open the DUPLICATEFASTA:$!\n";
	print "\nWARNING $1 is duplicated in fasta file";
    print DUPLICATEFASTA "$1\n";
	}
}

my $y=0;
my $duplicatetree="seq_duplicate_in_tree.txt";

open (LABELSDUPLICATECHECKINTREE,"<:encoding(UTF-8)", $Labels_duplicate_check_in_tree) or die "Cannot open the LABELSDUPLICATECHECKINTREE:$!\n";	
while (my $line_QC8=<LABELSDUPLICATECHECKINTREE>) {
	chomp $line_QC8;
	if ($line_QC8=~/>(.+)\t(.+)/ && $2>=2){
	$y++;
    open (DUPLICATETREE,">:encoding(UTF-8)",$duplicatetree) or die "Cannot open the DUPLICATETREE:$!\n";
	print "\nWARNING $1 is duplicated in tree file";
    print DUPLICATETREE "$1\n";
	}
}

close LABELSDUPLICATECHECKINFASTA; 
close LABELSDUPLICATECHECKINTREE;
close DUPLICATEFASTA;
close DUPLICATETREE;


my $z=$x+$y;
if ($z>0){
print "\nFix duplicates to avoid extraction issues","\n\n";
}
if ($z==0){
print "No duplicates found","\n\n";
}

#### Checking labels' concordance

print "Checking labels' concordance.....";

my $seqnotfasta="seq_not_in_fasta.txt";
my $seqnotree="seq_not_in_tree.txt";
my $k=0;
my $l=0;

foreach my $key (keys %hash1){
    if (!(exists $hash2{$key})){        # if $key does not exists as a key in hash2
    $k++;
    open (SEQNOFASTA,">:encoding(UTF-8)",$seqnotfasta) or die "Cannot open the SEQNOFASTA:$!\n";
    print "\nWARNING \"$key\" not in fasta file";
    print SEQNOFASTA "$key\n";
    }
}
foreach my $key (keys %hash2){
    if (!(exists $hash1{$key})){        # if $key does not exists as a key in hash1
    $l++;
    open (SEQNOTREE,">:encoding(UTF-8)",$seqnotree) or die "Cannot open the SEQNOTREE:$!\n";
    print "\nWARNING \"$key\" not in tree file";
    print SEQNOTREE "$key\n";
    }
}

my $m=$k+$l;
if ($m>0){
print "\nFix input files (e.g. for typo) for complete extraction","\n\n";
}
if ($m==0){
print "All labels matching","\n\n";
}

close SEQNOFASTA;
close SEQNOTREE;

#### Create a hash of labels as keys and print to file
#### Create a hash of colors as keys and print to file

open (PARSEDTREEFILE,'<', $Parsed_tree_file) or die "Cannot open the PARSEDTREEFILE:$!\n";

my $Labels_sorted_per_color="Temp/Labels_sorted_per_color.txt";
open (LABELSSORTEDPERCOLOR, ">:encoding(UTF-8)", $Labels_sorted_per_color) or die "Cannot open the LABELSSORTEDPERCOLOR:$!\n";

my $List_of_colors="Temp/List_of_colors.txt";
open (LISTOFCOLORS,">:encoding(UTF-8)",$List_of_colors) or die "Cannot open the LISTOFCOLORS:$!\n";

my %color_codes;
my %labels_colors;	
while (my $line4 = <PARSEDTREEFILE>){						# Loop through each line of the INFILE
	chomp $line4;
	my ($labels, $colors) = $line4 =~ /(.+)\t(.{6})_.+/;		# Parse the line into 2 variables: $labels and $colors; HEX code is 6 character long
	$labels_colors{$labels} = $colors;				# Populate the hash with: $labels as a key, $color as a value
	$color_codes{$colors}=();
}									# All the data are now in the hash. We can close the file

close PARSEDTREEFILE;

my $summary_color="summary_color.txt";
open (SUMMARYCOLOR, ">:encoding(UTF-8)", $summary_color) or die "Cannot open the SUMMARYCOLOR:$!\n";
print SUMMARYCOLOR "TAB_delimited\t\nOpen_in_spreadsheet_software_for_a_better_visual\t\n\nFile_title\:\t";

#### Output color lists
#print "Saving lists of colored labels to 'color_' files","\n";

foreach my $color (sort keys %color_codes){
	open (OUTFILECOLOR, ">:encoding(UTF-8)","lists_miscellaneous/color_$color.txt") or die "Cannot open the OUTFILECOLOR:$!\n";
	print SUMMARYCOLOR "\n$color\t";
foreach my $labels (sort {$labels_colors{$a} cmp $labels_colors{$b}} keys %labels_colors){
	if ($labels_colors{$labels} eq $color){	
	print OUTFILECOLOR "$labels\n";
	print SUMMARYCOLOR "$labels\t";
		}
	}
}

close OUTFILECOLOR;
close SUMMARYCOLOR;

#### Saving list of labels per color to file

foreach my $labels(sort {$labels_colors{$a} cmp $labels_colors{$b}} keys %labels_colors){
	print LABELSSORTEDPERCOLOR $labels,"\t", $labels_colors{$labels},"\n";
}

#### Saving list of color codes to file

foreach my $color (sort keys %color_codes){	
	print LISTOFCOLORS $color,"\n";
}

close LABELSSORTEDPERCOLOR;
close LISTOFCOLORS;

#### Create a hash of labels as keys and print to file
#### Create a hash of annotations as keys and print to file

open (PARSEDTREEFILE,'<', $Parsed_tree_file) or die "Cannot open the PARSEDTREEFILE:$!\n";

my $Labels_sorted_per_annotation="Temp/Labels_sorted_per_annotation.txt";
open (LABELSSORTEDPERANNOTATION, ">:encoding(UTF-8)", $Labels_sorted_per_annotation) or die "Cannot open the LABELSSORTEDPERANNOTATION:$!\n";

my $List_of_annotation="Temp/List_of_annotation.txt";
open (LISTOFANNOTATION,">:encoding(UTF-8)",$List_of_annotation) or die "Cannot open the LISTOFANNOTATION:$!\n";

my %annot_codes;
my %labels_annot;	
while (my $line5 = <PARSEDTREEFILE>){						# Loop through each line of the INFILE
	chomp $line5;
	my ($labels, $annot) = $line5 =~ /(.+)\t.{7}(.+)/;		# Parse the line into 2 variables: $labels and $annot; HEX code plus first underscore is 7 characters; this avoids parsing issues if the annotation contains an underscore
	$labels_annot{$labels} = $annot;				# Populate the hash with: $labels as a key, $annot as a value
	$annot_codes{$annot}=();
}									# All the data are now in the hash. We can close the file

close PARSEDTREEFILE;

my $summary_annot="summary_annot.txt";
open (SUMMARYANNOT, ">:encoding(UTF-8)", $summary_annot) or die "Cannot open the SUMMARYANNOT:$!\n";
print SUMMARYANNOT "TAB_delimited\t\nOpen_in_spreadsheet_software_for_a_better_visual\t\n\nFile_title\:\t";

#### Output annotation lists

#print "Saving lists of annotated labels to 'annot_' files","\n";

foreach my $annot (sort keys %annot_codes){
	open (OUTFILEANNOT, ">:encoding(UTF-8)","lists_miscellaneous/annot_$annot.txt") or die "Cannot open the OUTFILEANNOT:$!\n";
	print SUMMARYANNOT "\n$annot\t";
foreach my $labels (sort {$labels_annot{$a} cmp $labels_annot{$b}} keys %labels_annot){
	if ($labels_annot{$labels} eq $annot){	
	print OUTFILEANNOT "$labels\n";
	print SUMMARYANNOT "$labels\t";
		}
	}
}

close OUTFILEANNOT;
close SUMMARYANNOT;

#### Saving list of labels per annotation code to file

foreach my $labels(sort {$labels_annot{$a} cmp $labels_annot{$b}} keys %labels_annot){
	print LABELSSORTEDPERANNOTATION $labels,"\t", $labels_annot{$labels},"\n";
}

#### Saving list of annotation codes to file

foreach my $annot (sort keys %annot_codes){	
	print LISTOFANNOTATION $annot,"\n";
}

close LABELSSORTEDPERANNOTATION;
close LISTOFANNOTATION;

#### Create a hash of labels as keys and print to file
#### Create a hash of annotations as keys and print to file

open (PARSEDTREEFILE,'<', $Parsed_tree_file) or die "Cannot open the PARSEDTREEFILE:$!\n";

my $Labels_sorted_per_combo="Temp/Labels_sorted_per_combo.txt";
open (LABELSSORTEDPERCOMBO, ">:encoding(UTF-8)", $Labels_sorted_per_combo) or die "Cannot open the LABELSSORTEDPERCOMBO:$!\n";

my $List_of_combo="Temp/List_of_combo.txt";
open (LISTOFCOMBO,">:encoding(UTF-8)",$List_of_combo) or die "Cannot open the LISTOFCOMBO:$!\n";

my %combo_codes;
my %labels_combo;	
while (my $line6 = <PARSEDTREEFILE>){						# Loop through each line of the INFILE
	chomp $line6;
	my ($labels, $combo) = $line6 =~ /(.+)\t(.{6}_.+)/;		# Parse the line into 2 variables: $labels and $combo, HEX code is 6 character long
	$labels_combo{$labels} = $combo;				# Populate the hash with: $labels as a key, $combo as a value
	$combo_codes{$combo}=();
}									# All the data are now in the hash. We can close the file

close PARSEDTREEFILE;

my $summary_combo="summary_combo.txt";
open (SUMMARYCOMBO, ">:encoding(UTF-8)", $summary_combo) or die "Cannot open the SUMMARYCOMBO:$!\n";
print SUMMARYCOMBO "TAB_delimited\t\nOpen_in_spreadsheet_software_for_a_better_visual\t\n\nFile_title\:\t";

#### Output combo lists

#print "Saving lists of annotated+colored labels to 'combo_' files","\n";

foreach my $combo (sort keys %combo_codes){
	open (OUTFILECOMBO, ">:encoding(UTF-8)","lists_miscellaneous/combo_$combo.txt") or die "Cannot open the OUTFILECOMBO:$!\n";
	print SUMMARYCOMBO "\n$combo\t";
foreach my $labels (sort {$labels_combo{$a} cmp $labels_combo{$b}} keys %labels_combo){
	if ($labels_combo{$labels} eq $combo){	
	print OUTFILECOMBO "$labels\n";
	print SUMMARYCOMBO "$labels\t";
		}
	}
}

close OUTFILECOMBO;
close SUMMARYCOMBO;

#### Saving list of labels per combined code to file

foreach my $labels(sort {$labels_combo{$a} cmp $labels_combo{$b}} keys %labels_combo){
	print LABELSSORTEDPERCOMBO $labels,"\t", $labels_combo{$labels},"\n";
}

#### Saving list of combined codes to file

foreach my $combo (sort keys %combo_codes){	
	print LISTOFCOMBO $combo,"\n";
}

close LABELSSORTEDPERCOMBO;
close LISTOFCOMBO;

mkdir "FASTA_by_color_";  # Make folders where the different files will be printed
mkdir "FASTA_by_annot_";
mkdir "FASTA_by_combo_";

#### Open current directory

opendir DIRECTORY, "./lists_miscellaneous" or die "Could not open DIRECTORY:$!\n";

#### Store all file names of the directory into an array

my @files=readdir(DIRECTORY);

#### Close directory, no need to keep it open after filling the array

closedir(DIRECTORY);

#### Loop through the files and do the matching

print "\nExtracting fasta sequences...","\n\n";

my $n=0;
foreach my $infile(@files){
	if($infile=~/^\..*/){next;}	# Skip hidden files starting with a period
	if($infile=~/^(color_|annot_|combo_)(.+)\.txt/){   	# Process files starting by color_ or annot_ or combo_ and ending by .txt, isolate name $2 
		my @list_labels;		# Initiate arrays and loop through for each input file
		my @fasta_title_seq;	
		chdir "./lists_miscellaneous";
		open (INFILE,'<',$infile) or die "Cannot open the INFILE:$!\n";	
		while (my $line=<INFILE>) {	
	        	chomp $line;
                push (@list_labels, $line);
				}
		close INFILE;
		chdir "..";		
		open (OUTFILEFASTA, ">:encoding(UTF-8)","FASTA_by_$1/$2.fas") or die "Cannot open the OUTFILEFASTA:$!\n";		# Opening new file to print sequences to file named $2.fas from respective folder Fasta_by_$1
		open (TABULATEDFASTA,'<',$Tabulated_fasta) or die "Cannot open the TABULATEDFASTA:$!\n";
		while (my $sequence = <TABULATEDFASTA>){
			chomp $sequence;
			if ($sequence=~/>(.+)/){
				@fasta_title_seq = split (/\t/, $sequence);  # First element [0] is sequence title, second element [1] is actual sequence							
				foreach my $labels (@list_labels){		
					if ($fasta_title_seq[0] eq $labels){	
						print OUTFILEFASTA $fasta_title_seq[0], "\n", $fasta_title_seq[1], "\n"; 	# Matching labels in $2 to fasta file
					}
				}
			}
		}
	close TABULATEDFASTA;
	close OUTFILEFASTA; 		# From here, it moves to the next list of labels
	}
}


print "Cleaning up...\n\n";

unlink("Temp/All_fasta_labels.txt");
unlink("Temp/All_tree_labels.txt");
unlink("Temp/Labels_duplicate_check_in_fasta.txt");
unlink("Temp/Labels_duplicate_check_in_tree.txt");
unlink("Temp/Labels_sorted_per_annotation.txt");
unlink("Temp/Labels_sorted_per_color.txt");
unlink("Temp/Labels_sorted_per_combo.txt");
unlink("Temp/List_of_annotation.txt");
unlink("Temp/List_of_colors.txt");
unlink("Temp/List_of_combo.txt");
unlink("Temp/Parsed_tree_file.txt");
unlink("Temp/Tabulated_fasta.txt");
unlink("Temp/fasta.san");
unlink("Temp/tree.san");

my $dir = "Temp";
rmdir $dir;
if(-e $dir){
    print "Oops! it seems can't delete the directory 'Temp' on your system\n";
    print "Please do it manually\n\n";
}

print "TREE2FASTA is done!","\n";
print "\nSorted DNA sequence files are in the 'FASTA_by' folders\n";
print "Lists of headers are summarized in 'summary_by' files (table format)\n";
print "(If needed, individual lists are in the 'lists_miscellaneous' folder)\n\n";

#### Clean up the FASTA_by_color_ folder if no color selection was done on the tree
#### So we can also delete the content of the combo folder at the same time and unnecessary files in the lists_miscellaneous folder

opendir DIRECTORY, "./FASTA_by_color_" or die "Could not open DIRECTORY:$!\n";
my @filex1=readdir(DIRECTORY);
closedir(DIRECTORY);

my $filename1;
my $filecount1=0;
foreach my $infile(@filex1){
	if($infile=~/^\..*/){next;}	
	if($infile=~/^(.+)\.fas/){
		$filecount1++;
		$filename1=$1;
	}
}

if ($filecount1==1 && $filename1 eq 'NOCOLR'){
	unlink("summary_color.txt");
	unlink("summary_combo.txt");
	unlink("FASTA_by_color_/NOCOLR.fas");
	rmdir("FASTA_by_color_");
	opendir DIRECTORY, "./FASTA_by_combo_" or die "Could not open DIRECTORY:$!\n";
	my @filey=readdir(DIRECTORY);
	closedir(DIRECTORY);
	foreach my $infile(@filey){
		unlink("FASTA_by_combo_/$infile");
		rmdir("FASTA_by_combo_");
		}
	opendir DIRECTORY, "./lists_miscellaneous" or die "Could not open DIRECTORY:$!\n";
	my @filez=readdir(DIRECTORY);
	closedir(DIRECTORY);	
	foreach my $infile(@filez){	
		if($infile=~/^(color_|combo_)(.+)\.txt/){
		unlink("lists_miscellaneous/$infile");
			}
	}
}

#### Clean up the FASTA_by_annot_ folder if no annotation was done on the tree
#### So we can also delete the content of the combo folder at the same time and unnecessary files in the lists_miscellaneous folder

opendir DIRECTORY, "./FASTA_by_annot_" or die "Could not open DIRECTORY:$!\n";
my @filex2=readdir(DIRECTORY);
closedir(DIRECTORY);

my $filename2;
my $filecount2=0;
foreach my $infile(@filex2){
	if($infile=~/^\..*/){next;}	
	if($infile=~/^(.+)\.fas/){
		$filecount2++;
		$filename2=$1;
	}
}

if ($filecount2==1 && $filename2 eq 'NONAME'){
	unlink("summary_annot.txt");
	unlink("summary_combo.txt");
	unlink("FASTA_by_annot_/NONAME.fas");
	rmdir("FASTA_by_annot_");
	opendir DIRECTORY, "./FASTA_by_combo_" or die "Could not open DIRECTORY:$!\n";
	my @filey=readdir(DIRECTORY);
	closedir(DIRECTORY);
	foreach my $infile(@filey){
		unlink("FASTA_by_combo_/$infile");
		rmdir("FASTA_by_combo_");
		}
	opendir DIRECTORY, "./lists_miscellaneous" or die "Could not open DIRECTORY:$!\n";
	my @filez=readdir(DIRECTORY);
	closedir(DIRECTORY);	
	foreach my $infile(@filez){	
		if($infile=~/^(annot_|combo_)(.+)\.txt/){
		unlink("lists_miscellaneous/$infile");
			}
	}
}












