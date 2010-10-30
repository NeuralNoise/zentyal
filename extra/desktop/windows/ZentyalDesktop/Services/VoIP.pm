# Copyright (C) 2010 eBox Technologies S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package ZentyalDesktop::Services::VoIP;

use ZentyalDesktop::Config;

sub configure
{
    my ($class, $server, $user, $data) = @_;

    my $config = ZentyalDesktop::Config->instance();
    my $APPDATA = $config->appData();

    # FIXME: Unhardcode this
    my $TEMPLATES_DIR = './templates';

    my $password = ' ';

    open (my $templateFH, '<', "$TEMPLATES_DIR/ekiga.conf");
    my $template = join ('', <$templateFH>);
    close ($templateFH);

    $template =~ s/USERNAME/$USER/g;
    $template =~ s/SERVER/$SERVER/g;
    $template =~ s/PASSWORD/$PASSWORD/g;

    open (my $confFH, '>', "$APPDATA/ekiga.conf");
    print $confFH $template;
    close ($confFH);
}

1;
