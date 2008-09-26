package SVN::Look;

use warnings;
use strict;
use Switch;

=head1 NAME

SVN::Look - A caching wrapper aroung the svnlook command.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08.' . substr(q$Revision: 360 $, 10);

=head1 SYNOPSIS

  use SVN::Look;
  my $revlook = SVN::Look->new('/repo/path', -r => 123);
  my $author  = $revlook->author();
  my $msg     = $revlook->log_msg();
  my @added_files   = $revlook->added();
  my @updated_files = $revlook->updated();
  my @deleted_files = $revlook->deleted();
  my @changed_files = $revlook->changed();
  my $file_contents = $revlook->cat('/path/to/file/in/repository');

  my $trxlook = SVN::Look->new('/repo/path', -t => 123);

=head1 DESCRIPTION

The svnlook command is the workhorse of Subversion hook scripts, being
used to gather all sorts of information about a repository, its
revisions, and its transactions. This script provides a simple object
oriented interface to a specific svnlook invocation, to make it easier
to hook writers to get and use the information they need. Moreover,
all the information gathered buy calling the svnlook command is cached
in the object, avoiding repetitious calls.

=cut

our $SVNLOOK = '/usr/bin/svnlook';

=head1 METHODS

=over 4

=item B<new> REPO, WHAT, NUMBER

The SVN::Look constructor needs three arguments:

=over

=item REPO is the path to the repository.

=item WHAT must be either '-r' or '-t', specifying if the third
argument is a revision number or a transaction number, respectivelly.

=item NUMBER is either a revision or transaction NUMBER, as specified
by WHAT.

=back

=cut

sub new {
    my ($class, $repo, $what, $txn_or_rev) = @_;
    my $self = {
	repo     => $repo,
	args     => "$what $txn_or_rev",
	txn      => undef,
	rev      => undef,
	author   => undef,
	log      => undef,
	changed  => undef,
	proplist => undef,
    };
    switch ($what) {
	case '-t' { $self->{txn} = $txn_or_rev }
	case '-r' { $self->{rev} = $txn_or_rev }
	else      { die "Look::new: third argument must be -t or -r, not ($what)" }
    }
    bless $self, $class;
    return $self;
}

sub _svnlook {
    my ($self, $cmd, @args) = @_;
    my $svnlook_cmd = join(' ', $SVNLOOK, $cmd, $self->{repo}, $self->{args}, @args);
    open my $fd, '-|', $svnlook_cmd
	or die "Can't exec $svnlook_cmd: $!\n";
    if (wantarray) {
	my @lines = <$fd>;
	close $fd or die "Failed closing $svnlook_cmd: $!\n";
	chomp foreach @lines;
	return @lines;
    }
    else {
	local $/ = undef;
	my $line = <$fd>;
	close $fd or die "Failed closing $svnlook_cmd: $!\n";
	chomp $line;
	return $line;
    }
}

=item B<repo>

Returns the repository path that was passed to the constructor.

=cut

sub repo {
    my $self = shift;
    return $self->{repo};
}

=item B<txn>

Returns the transaction number that was passed to the constructor. If
none was passed, returns undef.

=cut

sub txn {
    my $self = shift;
    return $self->{txn};
}

=item B<rev>

Returns the revision number that was passed to the constructor. If
none was passed, returns undef.

=cut

sub rev {
    my $self = shift;
    return $self->{rev};
}

=item B<author>

Returns the author of the revision/transaction.

=cut

sub author {
    my $self = shift;
    unless ($self->{author}) {
	chomp($self->{author} = $self->_svnlook('author'));
    }
    return $self->{author};
}

=item B<log_msg>

Returns the log message of the revision/transaction.

=cut

sub log_msg {
    my $self = shift;
    unless ($self->{log}) {
	$self->{log} = $self->_svnlook('log');
    }
    return $self->{log};
}

=item B<date>

Returns the date of the revision/transaction.

=cut

sub date {
    my $self = shift;
    unless ($self->{date}) {
	$self->{date} = ($self->_svnlook('info'))[1];
    }
    return $self->{date};
}

=item B<proplist> PATH

Returns a reference to a hash containing the properties associated with PATH.

=cut

sub proplist {
    my ($self, $path) = @_;
    unless ($self->{proplist}{$path}) {
	my $text = $self->_svnlook('proplist', '--verbose', $path);
	my @list = split /^\s\s(\S+)\s:\s/m, $text;
	shift @list;		# skip the leading empty field
	chomp(my %hash = @list);
	$self->{proplist}{$path} = \%hash;
    }
    return $self->{proplist}{$path};
}

sub changed_hash {
    my $self = shift;
    unless ($self->{changed_hash}) {
	my (@added, @deleted, @updated, @prop_modified, %copied);
	foreach ($self->_svnlook('changed', '--copy-info')) {
	    next if length($_) <= 4;
	    chomp;
	    my ($action, $prop, undef, undef, $changed) = unpack 'AAAA A*', $_;
	    switch ($action) {
		case 'A' { push @added,    $changed }
		case 'D' { push @deleted,  $changed }
		case 'U' { push @updated, $changed }
		else {
		    if ($changed =~ /^\(from (.*?):r(\d+)\)$/) {
			$copied{$added[-1]} = [$1 => $2];
		    }
		}
	    }
	    if ($prop eq 'U') {
		push @prop_modified, $changed;
	    }
	}
	$self->{changed_hash} = {
	    added         => \@added,
	    deleted       => \@deleted,
	    updated       => \@updated,
	    prop_modified => \@prop_modified,
	    copied        => \%copied,
	};
    }
    return $self->{changed_hash};
}

=item B<added>

Returns the list of files added in the revision/transaction.

=cut

sub added {
    my $self = shift;
    return @{$self->changed_hash()->{added}};
}

=item B<updated>

Returns the list of files updated in the revision/transaction.

=cut

sub updated {
    my $self = shift;
    return @{$self->changed_hash()->{updated}};
}

=item B<deleted>

Returns the list of files deleted in the revision/transaction.

=cut

sub deleted {
    my $self = shift;
    return @{$self->changed_hash()->{deleted}};
}

=item B<prop_modified>

Returns the list of files that had properties modified in the
revision/transaction.

=cut

sub prop_modified {
    my $self = shift;
    return @{$self->changed_hash()->{prop_modified}};
}

=item B<changed>

Returns the list of all files added, updated, deleted, and the ones
that had properties modified in the revision/transaction.

=cut

sub changed {
    my $self = shift;
    my $hash = $self->changed_hash();
    unless (exists $hash->{changed}) {
	$hash->{changed} = [@{$hash->{added}}, @{$hash->{updated}}, @{$hash->{deleted}}, @{$hash->{prop_modified}}];
    }
    return @{$hash->{changed}};
}

=item B<dirs_changed>

Returns the list of directories changed in the revision/transaction.

=cut

sub dirs_changed {
    my $self = shift;
    unless (exists $self->{dirs_changed}) {
	my @dirs = $self->_svnlook('dirs-changed');
	$self->{dirs_changed} = \@dirs;
    }
    return @{$self->{dirs_changed}};
}

=item B<copied_from>

Returns the list of original names of files that were renamed in the
revision/transaction.

=cut

sub copied_from {
    my $self = shift;
    return keys %{$self->changed_hash()->{copied_from}};
}

=item B<copied_to>

Returns the list of new names of files that were renamed in the
revision/transaction. The order of this list is guaranteed to agree
with the order generated by the method copied_from.

=cut

sub copied_to {
    my $self = shift;
    return values %{$self->changed_hash()->{copied_from}};
}

=item B<cat> PATH

Returns the contents of the file at PATH.

=cut

sub cat {
    my ($self, $path) = @_;
    return $self->_svnlook('cat', $path);
}

=back

=head1 AUTHOR

Gustavo Chaves, C<< <gustavo+perl at gnustavo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svn-look at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Hooks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Look

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Hooks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Hooks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Hooks>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Hooks>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Gustavo Chaves, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SVN::Look
