package CATS::Problem;

use strict;
use warnings;

use CATS::Constants;

use fields qw(
    contest_id id description checker statement constraints input_format output_format formal_input
    json_data explanation tests testsets samples keywords current_tests
    imports solutions generators validators modules pictures attachments encoding stml
    zip zip_archive old_title replace repo has_checker de_list run_method
);

sub new
{
    my CATS::Problem $self = shift;
    my %args = @_;
    $self = fields::new($self) unless ref $self;
    $self->{$_} = defined $args{$_} ? $args{$_} : undef for qw(id repo contest_id old_title replace);
    return $self;
}

sub clear
{
    my CATS::Problem $self = shift;
    undef $self->{$_} for keys %CATS::Problem::FIELDS;
    $self->{$_} = {} for qw(tests test_defaults testsets samples keywords);
    $self->{$_} = [] for qw(imports solutions generators validators modules pictures attachments);
}

# sub set_description
# {
#     my CATS::Problem $self, $desc = shift;
#     for (qw(title lang time_limit memory_limit difficulty author input_file output_file std_checker max_points)) {
#         $self->{description}{$_} if de
#     }
# }

sub checker_type_names
{{
    legacy => $cats::checker,
    testlib => $cats::testlib_checker,
    partial => $cats::partial_checker,
}}

sub module_types()
{{
    'checker' => $cats::checker_module,
    'solution' => $cats::solution_module,
    'generator' => $cats::generator_module,
    'validator' => $cats::validator_module,
}}


1;
