package Perinci::Sub::Result::Table;

use 5.010001;
use strict;
use warnings;

1;
#ABSTRACT: Specify table data in result

=head1 SYNOPSIS

In function L<Rinci> metadata:

 result_table => {
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


=head1 DESCRIPTION

I often have functions that return table data, either in the form of array
(single-column rows):

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

This property lets you specify the kind of table data your function returns. The
value of this property should be a specification according to TableSpec (see
L<SHARYANTO::TableSpec>).

The wrapper code for this property will help add C<result_format_options>
property to your function result metadata, so when your subroutine outputs table
data in the console, the table will look prettier.

(NOT YET IMPLEMENTED) When you generate documentation, the table specification
is also included in the documentation.

=cut
