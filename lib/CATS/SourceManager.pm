package CATS::SourceManager;

use strict;
use warnings;

use CATS::Utils qw(get_absoulte_file_path);
use CATS::Constants;
use CATS::Problem::BinaryFile;

use IO::File;
use XML::Writer;
use XML::Parser::Expat;
use Scalar::Util qw(looks_like_number);

my $stml;
my $parsed_guid = {};

sub get_tags()
{[
    { o => 'id', r => 'id' },
    { o => 'stype', r => 'type' },
    { o => 'guid', r => 'guid' },
    { o => 'code', r => 'de_code' },
    { o => 'memory_limit', r => 'MemoryLimit' },
    { o => 'time_limit', r => 'TimeLimit' },
    { o => 'input_file', r => 'InputFile' },
    { o => 'output_file', r => 'OutputFile' },
    { o => 'fname', r => 'FileName' },
    { o => 'src', r => 'source' },
]}

sub on_end_tag
{
    my ($p, $el, %atts) = @_;
    for (@{get_tags()}) {
        if ($el eq $_->{r}) {
            $stml =~ s/^\s+//;
            $stml += 0 if looks_like_number($stml);
            $parsed_guid->{$_->{o}} = $stml ne '' ? $stml : undef;
            last;
        }
    }
    $stml = undef;
}

sub save {
    my ($sources, $dir) = @_;
    if (! -d $dir) {
        die "Unable to create $dir" unless mkdir $dir;
    }
    for my $source (@$sources) {
        next if !$source->{guid};
        my $fname = get_absoulte_file_path($dir, "$source->{guid}.xml");
        my $output = IO::File->new(">$fname") or die "Unable to open $fname for writing";
        my $writer = XML::Writer->new(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT => 3);
        $writer->startTag('description');
        for (@{get_tags()}) {
            $writer->startTag($_->{r});
            $writer->characters($source->{$_->{o}} ? $source->{$_->{o}} : '');
            $writer->endTag;
        }
        $writer->endTag;
        $writer->end;
        $output->close();
    }
}

sub load {
    my ($guid, $dir) = @_;
    my $fname = get_absoulte_file_path($dir, "$guid.xml");

    my $parser = new XML::Parser::Expat;
    $parser->setHandlers(
        Start => \&on_start_tag,
        End => \&on_end_tag,
        Char => sub { $stml .= $_[1] if defined $stml || (!defined $stml && $_[1] ne "\n") },
    );
    CATS::Problem::BinaryFile::load($fname, \my $data);
    $stml = undef;
    $parsed_guid = {};
    $parser->parse($data);
    return $parsed_guid;
}


1;
