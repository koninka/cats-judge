package CATS::Problem::ImportSource::Base;

use strict;
use warnings;

sub new
{
    my ($class) = shift;
    my $self = { @_ };
    bless $self, $class;
    $self;
}

sub get_source { (undef, undef); }

sub get_guids { (); }


package CATS::Problem::ImportSource::DB;

use strict;
use warnings;
use CATS::DB;
use base qw(CATS::Problem::ImportSource::Base);

sub get_source
{
    my ($self, $guid) = @_;
    $dbh->selectrow_array(qq~SELECT id, stype FROM problem_sources WHERE guid = ?~, undef, $guid);
}

sub get_guids
{
    my ($self, $guid) = @_;
    @{$dbh->selectcol_arrayref(qq~SELECT guid FROM problem_sources WHERE guid LIKE ? ESCAPE '\\'~, undef, $guid)};
}


package CATS::Problem::ImportSource::Local;

use strict;
use warnings;

use CATS::SourceManager;

use base qw(CATS::Problem::ImportSource::Base);

sub new
{
    my ($class, %opts) = @_;
    $opts{modules} or die 'You must specify modules folder';
    bless \%opts => $class;
}

sub get_source
{
    my ($self, $guid) = @_;
    my $source = CATS::SourceManager::load($guid, '/home/mark/development/cats-judge/modules');
    return $source->{id} && $source->{stype} ? ($source->{id}, $source->{stype}) : (undef, undef);
}

sub get_guids
{
    die 'Method ImportSource::Local::get_guids not implement yet';
}


1;
