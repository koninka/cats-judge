package CATS::Judge::Local;

use strict;
use warnings;

use Data::Dumper;

use CATS::Constants;
use CATS::SourceManager;
use CATS::Problem::Parser;
use CATS::Problem::ImportSource;
use CATS::Problem::Source::PlainFiles;

use base qw(CATS::Judge::Base);

sub auth {
    my ($self) = @_;
    return;
}

sub update_state {
    my ($self) = @_;
    0;
}

sub set_request_state {
    my ($self, $req, $state, %p) = @_;
}

sub select_request {
    my ($self, $supported_DEs) = @_;
    open FILE, $self->{source} or die "Couldn't open file: $!";
    {
        id => 0,
        problem_id => 0,
        contest_id => 0,
        state => 1,
        is_jury => 0,
        run_all_tests => 1,
        status => 0,
        fname => $self->{source},
        src => <FILE>,
        de_id => $self->{de}
    };
}

sub save_log_dump {
    my ($self, $req, $dump) = @_;
}

sub set_DEs {
    my ($self, $cfg_de) = @_;
    while (my ($key, $value) = each %$cfg_de) {
        $value->{code} = $value->{id} = $key;
    }
    $self->{supported_DEs} = $cfg_de;
}

sub pack_problem_source
{
    my ($self, %p) = @_;
    use Carp;
    my $s = $p{source_object} or confess;
    return {
        id => $s->{id},
        problem_id => 0,
        code => $s->{de_code},
        de_id => $self->{supported_DEs}{$s->{de_code}}{id},
        src => $s->{src},
        stype => $p{source_type},
        fname => $s->{path},
        input_file => $s->{inputFile},
        output_file => $s->{outputFile},
        guid => $s->{guid},
        time_limit => $s->{time_limit},
        memory_limit => $s->{memory_limit},
    }
}

sub get_problem_sources {
    my ($self, $pid, %opts) = @_;
    $self->{parser} = CATS::Problem::Parser->new(
        source => CATS::Problem::Source::PlainFiles->new(dir => $self->{dir}),
        import_source => CATS::Problem::ImportSource::DB->new(%opts),
    );
    my $problem;
    eval { $problem = $self->{parser}->parse; };
    die "Problem parsing failed: $@" if $@;

    for my $source (qw(validators generators solutions modules)) {
        for (@{$self->{parser}->{$source}}) {
            # die "Unsupported de: $_->{de_code}" if !exists $self->{supported_DEs}{$_->{de_code}};
            die "Unsupported de: $_->{de_code}" if !exists $self->{supported_DEs}{$_->{de_code}};
        }
    }

    my $problem_sources = [];
    if (my $c = $problem->{checker}) {
        push @$problem_sources, $self->pack_problem_source(
            source_object => $c, source_type => CATS::Problem::checker_type_names->{$c->{style}},
        );
    }

    for (@{$problem->{validators}}) {
        push @$problem_sources, $self->pack_problem_source(
            source_object => $_, source_type => $cats::validator,
        );
    }

    for(@{$problem->{generators}}) {
        push @$problem_sources, $self->pack_problem_source(
            source_object => $_, source_type => $cats::generator,
        );
    }

    for(@{$problem->{solutions}}) {
        push @$problem_sources, $self->pack_problem_source(
            source_object => $_, source_type => $_->{checkup} ? $cats::adv_solution : $cats::solution,
        );
    }

    for (@{$problem->{modules}}) {
        push @$problem_sources, $self->pack_problem_source(
            source_object => $_, source_type => $_->{type_code},
        );
    }
    # use Data::Dumper;
    # for (@$problem_sources) {
    #     delete $_->{src};
    #     warn Dumper($_);
    # }
    # die;
    for (@{$problem->{imports}}) {
        my $source = CATS::SourceManager::load($_->{guid}, $opts{modules});
        $source->{de_id} = $self->{supported_DEs}{$source->{code}}{id};
        $source->{problem_id} = 0;
        push @$problem_sources, $source;
    }

    [ @$problem_sources ];
}

sub delete_req_details {
    my ($self, $req_id) = @_;
}

sub insert_req_details {
    my ($self, $p) = @_;
}

sub get_problem_tests {
    my ($self, $pid) = @_;
    my $tests = [];
    for (sort { $a->{rank} <=> $b->{rank} } values %{$self->{parser}{problem}->{tests}}) {
        push @$tests, {
            generator_id => $_->{generator_id},
            rank => $_->{rank},
            param => $_->{param},
            std_solution_id => $_->{std_solution_id},
            in_file => $_->{in_file},
            out_file => $_->{out_file},
            gen_group => $_->{gen_group}
        };
    }
    [ @$tests ];
}

sub get_problem {
    my ($self, $pid) = @_;
    die "no parser" if !defined $self->{parser};
    my $p = $self->{parser}{problem}{description};
    {
        id => 0,
        title => $p->{title},
        upload_date => 0,
        time_limit => $p->{time_limit},
        memory_limit => $p->{memory_limit},
        input_file => $p->{input_file},
        output_file => $p->{output_file},
        std_checker => $p->{std_checker},
        contest_id => 0
    };
}

sub is_problem_uptodate { 1 }

sub get_testset { (0) }

1;
