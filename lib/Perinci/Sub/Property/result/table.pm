package Perinci::Sub::Property::result::table;

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Perinci::Sub::PropertyUtil qw(declare_property);

# VERSION

declare_property(
    name => 'result/table',
    type => 'function',
    schema => ['hash*'],
    wrapper => {
        meta => {
            v       => 2,
            prio    => 50,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = $args{new} // $args{value} // {};
            my $meta = $args{meta};

            # add result_format_options
            {
                last if $meta->{result_naked};
                $self->select_section('after_call_after_res_validation');
                $self->push_lines('# add result_format_options from result/table hints');
                $self->push_lines('{');
                $self->indent;
                $self->push_lines(
                    # we are in a local block, so no need to use _w_ prefixes
                    # for vars or even use add_var()
                    'last unless ref($_w_res->[2]) eq "ARRAY";',
                    'my $firstrow = $_w_res->[2][0] or last;', # deduce type from first row
                    'my $tablespec = '.$self->{_args}{meta_name}.'->{result}{table}{spec} or last;',
                    'my $tct = {};',
                    'my $tco;',
                    'if (ref($firstrow) eq "ARRAY" && $_w_res->[3]{"table.fields"}) {',
                    '    my $field_names = $_w_res->[3]{"table.fields"};', # map column\d to field names
                    '    for (0..@$field_names-1) {',
                    '        next if defined($tct->{$_});',
                    '        my $sch = $tablespec->{fields}{$field_names->[$_]}{schema} or next;', # field is unknown in table spec
                    '        my $type = ref($sch) eq "ARRAY" ? $sch->[0] : $sch;',
                    '        $type =~ s/\\*$//;',
                    '        $tct->{"column$_"} = $type;',
                    '    }',
                    '} elsif (ref($firstrow) eq "HASH") {',
                    '    my $fields = [keys %$firstrow];', # XXX should we check from several/all rows to collect more complete keys?
                    '    $tco = [sort {($tablespec->{fields}{$a}{pos} // $tablespec->{fields}{$a}{index} // 9999) <=> ($tablespec->{fields}{$b}{pos} // $tablespec->{fields}{$b}{index} // 9999)} @$fields];',
                    '    for (@$fields) {',
                    '        my $sch = $tablespec->{fields}{$_}{schema} or next;', # field is unknown in table spec
                    '        my $type = ref($sch) eq "ARRAY" ? $sch->[0] : $sch;',
                    '        $type =~ s/\\*$//;',
                    '        $tct->{$_} = $type;',
                    '    }',
                    '} else {',
                    '    last;',
                    '}',
                    'my $rfo = {};',
                    '$rfo->{table_column_types}  = [$tct] if $tct;',
                    '$rfo->{table_column_orders} = [$tco] if $tco;',
                    '$_w_res->[3]{result_format_options}                //= {};',
                    '$_w_res->[3]{result_format_options}{text}          //= $rfo;',
                    '$_w_res->[3]{result_format_options}{"text-pretty"} //= $rfo;',
                );
                $self->unindent;
                $self->push_lines('}');
            }

            # TODO validate table data, if requested
        },
    },
);


1;
#ABSTRACT: Specify table data in result

=head1 SYNOPSIS

In function L<Rinci> metadata:

 result => {
     table => {
         spec => {
             summary => "Employee's' current salary",
             fields  => {
                 name => {
                     summary => "Employee's name",
                     schema  => 'str*',
                     pos     => 0,
                 },
                 position => {
                     summary => "Employee's current position",
                     schema  => 'str*',
                     pos     => 1,
                 },
                 salary => {
                     summary => "Employee's current monthly salary",
                     schema  => 'float*',
                     pos     => 2,
                 },
             },
         },
         # allow_extra_fields => 0,
         # allow_underscore_fields => 0,
     },
     ...
 }


=head1 DESCRIPTION

If your function returns table data, either in the form of array (single-column
rows):

 ["andi", "budi", "cinta", ...]

or array of arrays (CSV-like):

 [
   ["andi" , "manager", 12_000_000],
   ["budi" , "staff", 5_000_000],
   ["cinta", "junior manager", 7_500_000],
   # ...
 ]

or array of hashes (with field names):

 [
   {name=>"andi" , position=>"manager", salary=>12_000_000},
   {name=>"budi" , position=>"staff", salary=> 5_000_000},
   {name=>"cinta", position=>"junior manager", salary=> 7_500_000},
   # ...
 ]

then you might want to add a C<table> property inside your C<result> property of
your function metadata. This module offers several things:

=over

=item *

When your function is run under L<Perinci::CmdLine>, your tables will look
prettier. This is done via adding C<result_format_options> property to your
function result metadata, giving hints to the L<Data::Format::Pretty> formatter.

=item *

(NOT YET IMPLEMENTED) When you generate documentation, the table specification
is also included in the documentation.

(NOT YET IMPLEMENTED, IDEA) The user can also perhaps request the table
specification, e.g. C<yourfunc --help=result-table-spec>, C<yourfunc
--result-table-spec>.

=item *

(NOT YET IMPLEMENTED) The wrapper code can optionally validate your function
result, making sure that your resulting table conforms to the table
specification.

=item *

(NOT YET IMPLEMENTED, IDEA) The wrapper code can optionally filter, summarize,
or sort the table on the fly before returning the final result to the user.

(Alternatively, you can pipe the output to another tool like B<jq>, just like a
la Unix toolbox philosophy).

=back


=head1 SPECIFICATION

The value of the C<table> property should be a L<DefHash>. Known properties:

=over

=item * spec => DEFHASH

Required. Table data specification, specified using L<SHARYANTO::TableSpec>.

=item * allow_extra_fields => BOOL (default: 0)

Whether to allow the function to return extra fields other than the ones
specified in C<spec>. This is only relevant when function returns array of
hashes (i.e. when the field names are present). And this is only relevant when
validating the table data.

=item * allow_underscore_fields => BOOL (default: 0)

Like C<allow_extra_fields>, but regulates whether to allow any extra fields
prefixed by an underscore. Underscore-prefixed keys is the DefHash's convention
of extra keys that can be ignored.

=back


=head1 NOTES

If you return an array or array of arrays (i.e. no field names), you might want
to add C<table.fields> result metadata so the wrapper code can know which
element belongs to which field. Example:

 my $table = [];
 push @$table, ["andi", 1];
 push @$table, ["budi", 2];
 return [200, "OK", $table, {"table.fields"=>[qw/name id/]}];

This is not needed if you return array of hashes, since the field names are
present as hash keys:

 my $table = [];
 push @$table, {name=>"andi", id=>1};
 push @$table, {name=>"budi", id=>2};
 return [200, "OK", $table];


=head1 RESULT METADATA

=over

=item * attribute: table.fields => ARRAY OF STR

=back


=head1 FAQ

=head2 Why not use the C<schema> property in the C<result> property?

That is, in your function metadata:

 result => {
     schema => ['array*', of => ['hash*' => keys => {
         name => 'str*',
         position => 'str',
         salary => ['float*', min => 0],
         ...
     }]],
 },

First of all, table data can come in several forms, either a 1-dimensional
array, an array of arrays, or an array of hashes. Moreover, when returning an
array of arrays, the order of fields can sometimes be changed. The above schema
will become more complex if it has to handle all those cases.

With the C<table> property, the intent becomes clearer that we want to return
table data. We can also specify more aspects aside from just the schema.

=cut
