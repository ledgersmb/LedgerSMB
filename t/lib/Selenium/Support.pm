=head1 NAME

Selenium::Support - Helper routines for testing ajax Web Apps with Selenium

=head1 SYNOPSIS

To wait for a page's processing to be complete (including ajax requests):

  my $driver = Selenium::Remote::Driver->new();
  prepare_driver($driver);
  $driver->get("https://www.example.com/");
  try_wait_for_page($driver);

=cut

package Selenium::Support;

use Carp;
use Exporter;
use Time::HiRes qw(time);
use Test::More;

use Selenium::Waiter qw(wait_until);

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    find_element_by_label
    find_button
    find_dropdown
    find_option
    try_wait_for_page prepare_driver
    element_has_class element_is_dropdown);


# In order to estimate the number of running ajax requests, we need
# to patch the XMLHttpRequest object prototype: that way we can install
# an open() method which adds an event listener.

sub _monkeypatch_xml_http_prototype {
    my ($driver) = @_;

    # my thanks go to
    # http://stackoverflow.com/questions/9267451/how-to-check-if-http-requests-are-open-in-browser

    $driver->execute_script(qq(
(function() {
    var oldOpen = XMLHttpRequest.prototype.open;
    window.__SELENIUM_538268 = 0;
    XMLHttpRequest.prototype.open = function(method, url, async, user, pass) {
      window.__SELENIUM_538268++;
      this.addEventListener("readystatechange", function() {
          if(this.readyState == 4) {
            window.__SELENIUM_538268--;
          }
        }, false);
      oldOpen.call(this, method, url, async, user, pass);
    }
  })();
));

}


=head1 METHODS

=over

=item prepare_driver($driver)

Installs some hooks in the browser(window) owned by the driver
to allow better waiting for any page activity to complete.

=cut

sub prepare_driver {
    my ($driver) = @_;
    &_monkeypatch_xml_http_prototype($driver);
}


=item find_element_by_label($driver, $label)

Finds a label with the text equal to $label. Then looks up the
associated element through the 'for' attribute of the label.

=cut


sub find_element_by_label {
    my ($driver, $label) = @_;

    my $label_element = $driver->find_element("//label[text()='$label']");
    do {
        croak "no label with text '$label'";
        return;
    } unless defined $label_element;

    my $element_id = $label_element->get_attribute('for');
    do {
        croak "no 'for' attribute of element with label '$label'";
        return;
    } unless defined $element_id;

    my $element = $driver->find_element("//*[\@id='$element_id']");
    do {
        croak "no element with label '$label' and id '$element_id' found";
        return;
    } unless defined $element;

    return $element;
}


=item element_has_class($element, $class)

Returns false if the element's 'class' attribute doesn't contain $class.

=cut

sub element_has_class {
    my ($element, $class) = @_;

    my $class_attr = $element->get_attribute('class');
    my $rv =
        grep { $_ eq $class }
        split /[\s\t\n]+/, $class_attr;

    return $rv;
}


=item find_button($driver, $text)


=cut

sub find_button {
    my ($driver, $text) = @_;

    my $btn = $driver->find_element(
        "//span[text()='$text'
                and contains(concat(' ',normalize-space(\@class),' '),
                             ' dijitButtonText ')]
         | //button[text()='$text']
         | //input[\@value='$text'
                   and (\@type='submit' or \@type='image' or \@type='reset')]");
    ok($btn, "found button tag '$button_text'");

    return $btn;
}


=item element_is_dropdown($element)


=cut

sub element_is_dropdown {
    my ($elm) = @_;

    return ($elm->get_tag_name eq 'select'
            || element_has_class($elm, 'dijitSelect'));
}

=item find_dropdown($driver, $text)


=cut

sub find_dropdown {
    my ($driver, $label) = @_;

    my $elm = find_element_by_label($driver,$label);
    ok(element_is_dropdown($elm),
       "Found drop down element '$label'");

    return $elm;
}

=item find_option($driver, $text, $dropdown)


=cut


sub find_option {
    my ($driver, $text, $dropdown) = @_;

    my $elm = find_dropdown($driver, $dropdown);

    my $dd;
    if ($elm->get_tag_name ne 'select') {
        # dojo
        my $id = $elm->get_attribute('id');
        $elm->click;
        $elm->click;
        $dd = $driver->find_element("//*[\@dijitpopupparent='$id']");
    }
    else {
        $dd = $elm;
    }
    my $option =
        $driver->find_child_element($dd,".//*[text()='$text']");
    ok($option, "Found option with value '$text' of dropdown '$dropdown'");
    if (! $option->is_displayed) {
        $elm->click;
        $driver->execute_script(qq#arguments[0].scrollIntoView();#, $option);
    }

    return $option;
}



=item try_wait_for_page($driver)

Waits for page activity to quiet down. Takes Dojo's page activity into account
as well as any runnnig ajax requests.

When the page is estimated to be busy, sleeps for a short period and tries
again.

Bails out after waiting more than 10 seconds.

=cut



our $max_wait_secs = 10;
my $page_generation = 0;
sub try_wait_for_page {
    my ($driver) = @_;


    wait_until { $driver->find_element('body.done-parsing', 'css') };

    $page_generation++;
    $driver->execute_script(qq(
if (dojo && require) {
  require(["dojo/ready"], function(ready) {
     ready(9999, function() { window.__SELENIUM_5382645 = $page_generation; })
  });
}
else {
   // detection failed
   window.__SELENIUM_5382645 = $page_generation;
}
));

    my $start_time = time();
    while (((time() - $start_time) < $max_wait_secs)
           && $driver->execute_script(qq(
 return ((window.__SELENIUM_5382645 < $page_generation)
         || (window.__SELENIUM_538268 > 0))
       ))){
        sleep(0.05);
    };
}

1;
