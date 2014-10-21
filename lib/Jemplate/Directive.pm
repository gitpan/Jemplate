package Jemplate::Directive;
use strict;
use warnings;

our $OUTPUT = 'output +=';
our $WHILE_MAX = 1000;

sub template {
    my ($class, $block) = @_;

    return "sub { return '' }" unless $block =~ /\S/;

    return <<"...";
function(context) {
    if (! context) throw('Jemplate function called without context\\n');
    var stash = context.stash;
    var output = '';

    try {
$block
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}
...
}
 
#------------------------------------------------------------------------
# textblock($text)
#------------------------------------------------------------------------

sub textblock {
    my ($class, $text) = @_;
    return "$OUTPUT " . $class->text($text) . ';';
}

#------------------------------------------------------------------------
# text($text)
#------------------------------------------------------------------------

sub text {
    my ($class, $text) = @_;
    for ($text) {
        s/([\'\\])/\\$1/g;
        s/\n/\\n/g;
    }
    return "'" . $text . "'";
}

#------------------------------------------------------------------------
# ident(\@ident)                                             foo.bar(baz)
#------------------------------------------------------------------------

sub ident {
    my ($class, $ident) = @_;
    return "''" unless @$ident;
    my $ns;

    # does the first element of the identifier have a NAMESPACE
    # handler defined?
    if (ref $class && @$ident > 2 && ($ns = $class->{ NAMESPACE })) {
        my $key = $ident->[0];
        $key =~ s/^'(.+)'$/$1/s;
        if ($ns = $ns->{ $key }) {
            return $ns->ident($ident);
        }
    }

    if (scalar @$ident <= 2 && ! $ident->[1]) {
        $ident = $ident->[0];
    }
    else {
        $ident = '[' . join(', ', @$ident) . ']';
    }
    return "stash.get($ident)";
}


#------------------------------------------------------------------------
# assign(\@ident, $value, $default)                             foo = bar
#------------------------------------------------------------------------

sub assign {
    my ($class, $var, $val, $default) = @_;

    if (ref $var) {
        if (scalar @$var == 2 && ! $var->[1]) {
            $var = $var->[0];
        }
        else {
            $var = '[' . join(', ', @$var) . ']';
        }
    }
    $val .= ', 1' if $default;
    return "stash.set($var, $val)";
}


#------------------------------------------------------------------------
# args(\@args)                                        foo, bar, baz = qux
#------------------------------------------------------------------------

sub args {
    my ($class, $args) = @_;
    my $hash = shift @$args;
    push(@$args, '{ ' . join(', ', @$hash) . ' }')
        if @$hash;

    return '0' unless @$args;
    return '[ ' . join(', ', @$args) . ' ]';
}


#------------------------------------------------------------------------
# filenames(\@names)
#------------------------------------------------------------------------
    
sub filenames {
    my ($class, $names) = @_;
    if (@$names > 1) {
        $names = '[ ' . join(', ', @$names) . ' ]';
    }
    else {
        $names = shift @$names;
    }
    return $names;
}   
    
        
#------------------------------------------------------------------------
# get($expr)                                                    [% foo %]
#------------------------------------------------------------------------

sub get {
    my ($class, $expr) = @_;
    return "$OUTPUT $expr;";
}   

sub block {
    my ($class, $block) = @_;
    return join "\n", map {
        s/^#(?=line \d+)/\/\//gm;
        $_;
    } @{ $block || [] };
}

#------------------------------------------------------------------------
# call($expr)                                              [% CALL bar %]
#------------------------------------------------------------------------

sub call {
    my ($class, $expr) = @_;
    $expr .= ';';
    return $expr;
}


#------------------------------------------------------------------------
# set(\@setlist)                               [% foo = bar, baz = qux %]
#------------------------------------------------------------------------

sub set {
    my ($class, $setlist) = @_;
    my $output;
    while (my ($var, $val) = splice(@$setlist, 0, 2)) {
        $output .= $class->assign($var, $val) . ";\n";
    }
    chomp $output;
    return $output;
}


#------------------------------------------------------------------------
# include(\@nameargs)                    [% INCLUDE template foo = bar %] 
#         # => [ [ $file, ... ], \@args ]
#------------------------------------------------------------------------

sub include {
    my ($class, $nameargs) = @_;
    my ($file, $args) = @$nameargs;
    my $hash = shift @$args;
    s/ => /: / for @$hash;
    $file = $class->filenames($file);
    $file .= @$hash ? ', { ' . join(', ', @$hash) . ' }' : '';
    return "$OUTPUT context.include($file);"; 
}   
    
        
#------------------------------------------------------------------------
# process(\@nameargs)                    [% PROCESS template foo = bar %] 
#         # => [ [ $file, ... ], \@args ]
#------------------------------------------------------------------------

sub process {
    my ($class, $nameargs) = @_;
    my ($file, $args) = @$nameargs;
    my $hash = shift @$args;
    s/ => /: / for @$hash;
    $file = $class->filenames($file);
    $file .= @$hash ? ', { ' . join(', ', @$hash) . ' }' : '';
    return "$OUTPUT context.process($file);"; 
}   
    
        
#------------------------------------------------------------------------
# if($expr, $block, $else)                             [% IF foo < bar %]
#                                                         ...
#                                                      [% ELSE %]
#                                                         ...
#                                                      [% END %]
#------------------------------------------------------------------------
    
sub if {
    my ($class, $expr, $block, $else) = @_;
    my @else = $else ? @$else : ();
    $else = pop @else;

    $expr = _fix_expr($expr);
    my $output = "if ($expr) {\n$block\n}\n";
        
    foreach my $elsif (@else) {
        ($expr, $block) = @$elsif;
        $expr = _fix_expr($expr);
        $output .= "else if ($expr) {\n$block\n}\n";
    }   
    if (defined $else) {
        $output .= "else {\n$else\n}\n";
    }

    return $output;
}

# XXX A very nasty hack until I learn more.
sub _fix_expr {
    my $expr = shift;
    $expr =~ s/ eq / == /g;
    return $expr;
}

#------------------------------------------------------------------------
# foreach($target, $list, $args, $block)    [% FOREACH x = [ foo bar ] %]
#                                              ...
#                                           [% END %]
#------------------------------------------------------------------------

sub foreach {
    my ($class, $target, $list, $args, $block) = @_;
    $args  = shift @$args;
    $args  = @$args ? ', { ' . join(', ', @$args) . ' }' : '';

    my ($loop_save, $loop_set, $loop_restore, $setiter);
    if ($target) {
        $loop_save =
            'try { oldloop = ' . $class->ident(["'loop'"]) . ' } finally {}';
        $loop_set = "stash['$target'] = value";
        $loop_restore = "stash.set('loop', oldloop)";
    }
    else {
        die "XXX - Not supported yet";
        $loop_save = 'stash = context.localise()';
        $loop_set =
            "stash.get(['import', [value]]) if typeof(value) == 'object'";
        $loop_restore = 'stash = context.delocalise()';
    }

    return <<EOF;

// FOREACH 
(function() {
    var list = $list;
    list = new Jemplate.Iterator(list);
    var retval = list.get_first();
    var value = retval[0];
    var done = retval[1];
    var oldloop;
    $loop_save
    stash.set('loop', list);
    try {
        while (! done) {
            $loop_set;
$block;
            retval = list.get_next();
            var value = retval[0];
            var done = retval[1];
        }
    }
    catch(e) {
        throw(context.set_error(e, output));
    }
    $loop_restore;
})();
EOF
}


#------------------------------------------------------------------------
# next()                                                       [% NEXT %]
#
# Next iteration of a FOREACH loop (experimental)
#------------------------------------------------------------------------

sub next {
    return "continue;";
}


#------------------------------------------------------------------------
# while($expr, $block)                                 [% WHILE x < 10 %]
#                                                         ...
#                                                      [% END %]
#------------------------------------------------------------------------

sub while {
    my ($class, $expr, $block) = @_; 
    
    return <<EOF;
    
// WHILE
var failsafe = $WHILE_MAX;
while (--failsafe && ($expr)) {
$block
}
if (! failsafe)
    throw("WHILE loop terminated (> $WHILE_MAX iterations)\\n")
EOF
}


#------------------------------------------------------------------------
# clear()                                                     [% CLEAR %]
#   
# NOTE: this is redundant, being hard-coded (for now) into Parser.yp
#------------------------------------------------------------------------

sub clear {
    return "output = '';";
}


#------------------------------------------------------------------------
# break()                                                     [% BREAK %]
#   
# NOTE: this is redundant, being hard-coded (for now) into Parser.yp
#------------------------------------------------------------------------

sub break {
    return 'break;';
}                       
        
#------------------------------------------------------------------------
# return()                                                   [% RETURN %]
#------------------------------------------------------------------------

sub return {
    return "return output;"
}


#------------------------------------------------------------------------
# stop()                                                       [% STOP %]
#------------------------------------------------------------------------

sub stop {
    return "throw('Jemplate.STOP\\n' + output);";
}   

    
1;

=head1 NAME

Jemplate::Directive - Jemplate Code Generating Backend

=head1 SYNOPSIS

    use Jemplate::Directive;

=head1 DESCRIPTION

Jemplate::Directive is the analog to Template::Directive, which is the
module that produces that actual code that templates turn into. The
Jemplate version obviously produces Javascript code rather than Perl.
Other than that the two modules are almost exactly the same.

=head1 BUGS

Unfortunately, some of the code generation seems to happen before
Jemplate::Directive gets control. So it currently has heuristical code
to rejigger Perl code snippets into Javascript. This processing needs to
happen upstream once I get more clarity on how Template::Toolkit works.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
