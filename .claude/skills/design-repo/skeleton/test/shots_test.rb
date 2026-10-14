# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"

# What bin/shots captures from a page, and which pages it refuses.
#
# A page is a snapshot of the application: one surface, every state reached from a state bar, and
# nothing that describes the application beside it. The shots are what a reader looks at, so they
# hold the surface alone — a paragraph drawn next to it never reaches one — and a page that does not
# keep the contract is named rather than shot. Each test runs the script over throwaway pages.
#
# A page with many states groups them into families: a Family row picks one, and the State row shows
# that family's states alone, each labelled with its name less the family. Its shots still cover every
# state, including those whose tabs the bar is hiding, and a family split apart, a state outside its
# family's name or one repeating it is named, since the bar steps through them in page order.
#
# It needs node and a browser, which a fresh clone and CI may not have; then it skips and says so.
class ShotsTest < Minitest::Test
  SCRIPT = File.expand_path("../bin/shots", __dir__)

  def setup
    @dir = Dir.mktmpdir("design-repo-shots")
    @pages = File.join(@dir, "pages")
    @out = File.join(@dir, "shots")
    FileUtils.mkdir_p(@pages)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_every_state_a_page_names_is_shot_from_its_state_bar_and_named_for_it
    page "books.html", states: ["Empty", "Long data"]

    out, status = shots

    assert status.success?, out
    assert_equal %w[01-empty.png 02-long-data.png], Dir.children(File.join(@out, "books")).sort
  end

  def test_a_shot_holds_the_application_surface_alone_never_the_prose_beside_it
    page "books.html", states: ["Empty"], prose: "<p style='height:400px'>The list empties when the last book is archived.</p>"

    out, status = shots

    assert status.success?, out
    assert_equal [600, 400], png_size(File.join(@out, "books/01-empty.png")), "the surface is 300x200 CSS pixels at 2x"
  end

  def test_a_page_with_several_states_and_no_state_bar_is_refused_and_named
    page "books.html", states: %w[Empty Error], bar: false

    out, status = shots

    assert_equal 1, status.exitstatus
    assert_match(/books\.html: has 2 states and no state bar/, out)
  end

  def test_a_page_with_no_surface_is_refused_and_named
    page "books.html", states: ["Empty"], surface: false

    out, status = shots

    assert_equal 1, status.exitstatus
    assert_match(/books\.html: has 0 \[data-surface\] elements/, out)
  end

  def test_a_state_bar_that_disagrees_with_the_states_is_refused
    page "books.html", states: %w[Empty Error], tabs: %w[Empty Failed]

    out, status = shots

    assert_equal 1, status.exitstatus
    assert_match(/books\.html: its state bar reads/, out)
  end

  def test_a_grouped_page_is_shot_in_every_state_of_every_family_though_the_bar_hides_other_families
    page "books.html", states: ["List", "List · Filtered", "Record · Read", "Record · Edit"], families: true

    out, status = shots

    assert status.success?, out
    assert_equal %w[01-list.png 02-list-filtered.png 03-record-read.png 04-record-edit.png],
                 Dir.children(File.join(@out, "books")).sort
  end

  def test_a_family_whose_states_do_not_sit_together_is_refused
    page "books.html", states: ["List", "Record · Read", "List · Filtered"], families: true

    out, status = shots

    assert_equal 1, status.exitstatus
    assert_match(/books\.html: its "List" family is split/, out)
  end

  def test_a_state_not_named_for_its_family_is_refused
    page "books.html", states: ["List", "Read · classified"], families: %w[List Classify]

    out, status = shots

    assert_equal 1, status.exitstatus
    assert_match(/books\.html: its state "Read · classified" does not start with its family "Classify"/, out)
  end

  def test_a_state_repeating_its_family_is_refused
    page "books.html", states: ["Book", "Book · Sparse book", "List"], families: true

    out, status = shots

    assert_equal 1, status.exitstatus
    assert_match(/books\.html: its state "Book · Sparse book" repeats its family/, out)
  end

  private

  # families: true takes each state's family from its name; an array gives them outright. The bar is
  # drawn as a grouped page draws it: a Family row, and a State row showing the current family's tabs.
  def page(name, states:, bar: true, surface: true, tabs: states, prose: "", families: nil)
    families = states.map { |s| s.split(" · ").first } if families == true
    panels = states.each_with_index.map do |state, i|
      family = %( data-family="#{families[i]}") if families
      %(<section data-state="#{state}"#{family}#{' hidden' unless i.zero?} style="height:200px">#{state}</section>)
    end
    labels = families ? states.each_with_index.map { |s, i| s == families[i] ? "Default" : s.delete_prefix("#{families[i]} · ") } : tabs
    buttons = labels.each_with_index.map { |tab, i| %(<button role="tab" data-i="#{i}">#{tab}</button>) }
    family_row = families.uniq.map { |f| %(<button data-f="#{f}">#{f}</button>) }.join if families
    File.write(File.join(@pages, name), <<~HTML)
      <!doctype html><meta charset="utf-8"><body style="margin:0">
      <main #{'data-surface' if surface} style="width:300px">#{panels.join}</main>
      #{prose}
      #{%(<nav role="tablist" aria-label="State">#{family_row}#{buttons.join}</nav>) if bar}
      <script>
        const panels = [...document.querySelectorAll("[data-state]")];
        const tabs = [...document.querySelectorAll('[role="tab"]')];
        const show = (i) => {
          panels.forEach((p, j) => (p.hidden = j !== i));
          tabs.forEach((t, j) => (t.hidden = panels[j].dataset.family !== panels[i].dataset.family));
        };
        tabs.forEach((b) => (b.onclick = () => show(+b.dataset.i)));
        document.querySelectorAll("[data-f]").forEach((b) =>
          b.onclick = () => show(panels.findIndex((p) => p.dataset.family === b.dataset.f)));
        show(0);
      </script>
    HTML
  end

  def shots
    out, err, status = Open3.capture3(SCRIPT, @pages, @out)
    skip "bin/shots cannot run here — #{err.lines.first&.strip}" if status.exitstatus == 2
    [out + err, status]
  end

  def png_size(path)
    File.binread(path, 24, 16).unpack("NN")
  end
end
