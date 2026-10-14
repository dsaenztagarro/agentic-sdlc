# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"

# What bin/sync lets into this repository.
#
# The mirror is `rsync --delete`, so whatever an export carries becomes this repository's truth,
# and every refusal has to happen before anything is copied. Each test runs a copy of bin/sync in
# a throwaway checkout, set to the export kind under test, because the script resolves its target
# from its own location and a real run would mirror over this repository.
class SyncTest < Minitest::Test
  SCRIPT = File.expand_path("../bin/sync", __dir__)

  def teardown
    FileUtils.rm_rf(@root) if @root
  end

  def test_a_project_export_is_mirrored_into_pages_with_its_design_system_snapshot
    checkout(kind: "project")
    project_export

    status, err = sync

    assert status.success?, err
    assert_path_exists File.join(@root, "pages/books.html")
    assert_path_exists File.join(@root, "pages/_ds/shared/_ds_manifest.json")
  end

  def test_a_project_mirror_is_followed_by_shots_and_a_breach_does_not_undo_it
    checkout(kind: "project")
    project_export
    File.write(File.join(@root, "bin/shots"), "#!/bin/sh\ntouch \"$(dirname \"$0\")/../shot\"\nexit 1\n")
    File.chmod(0o755, File.join(@root, "bin/shots"))

    status, err = sync

    assert status.success?, err
    assert_path_exists File.join(@root, "shot")
    assert_path_exists File.join(@root, "pages/books.html")
  end

  def test_a_design_system_export_is_mirrored_into_system
    checkout(kind: "system")
    system_export

    status, err = sync

    assert status.success?, err
    assert_path_exists File.join(@root, "system/components/button.css")
  end

  def test_an_export_of_the_other_kind_is_refused
    checkout(kind: "system")
    project_export

    status, err = sync

    refute status.success?
    assert_includes err, "project export"
    refute_path_exists File.join(@root, "system")
  end

  def test_a_page_that_is_not_one_canonical_prototype_per_surface_is_refused
    checkout(kind: "project")
    project_export
    %w[books-v2.html timer\ v1.html parity-audit.html tab-rationale.html back-link-options.html].each do |page|
      File.write(File.join(@export, page), "")
    end

    status, err = sync

    refute status.success?
    %w[books-v2.html timer\ v1.html parity-audit.html tab-rationale.html back-link-options.html].each do |page|
      assert_includes err, page
    end
    refute_path_exists File.join(@root, "pages")
  end

  def test_an_export_that_disagrees_with_a_file_authored_here_is_refused
    checkout(kind: "system", upstream: ["tokens/colors.css"])
    system_export
    FileUtils.mkdir_p(File.join(@root, "system/tokens"))
    File.write(File.join(@root, "system/tokens/colors.css"), "--accent: blue;")
    File.write(File.join(@export, "tokens/colors.css"), "--accent: red;")

    status, err = sync

    refute status.success?
    assert_includes err, "tokens/colors.css"
    assert_equal "--accent: blue;", File.read(File.join(@root, "system/tokens/colors.css"))
  end

  private

  def checkout(kind:, upstream: [])
    @root = Dir.mktmpdir("design-repo-sync")
    FileUtils.mkdir_p(File.join(@root, "bin"))
    script = File.read(SCRIPT)
      .sub(/^KIND=".*"$/, %(KIND="#{kind}"))
      .sub(/^UPSTREAM=\(.*\)$/, "UPSTREAM=(#{upstream.join(' ')})")
    File.write(File.join(@root, "bin/sync"), script)
    File.chmod(0o755, File.join(@root, "bin/sync"))
    @export = File.join(@root, "export")
  end

  def project_export
    FileUtils.mkdir_p(File.join(@export, "_ds/shared"))
    File.write(File.join(@export, "_ds/shared/_ds_manifest.json"), "{}")
    File.write(File.join(@export, "books.html"), "<main></main>")
  end

  def system_export
    FileUtils.mkdir_p(File.join(@export, "components"))
    FileUtils.mkdir_p(File.join(@export, "tokens"))
    File.write(File.join(@export, "_ds_manifest.json"), "{}")
    File.write(File.join(@export, "components/button.css"), ".btn{}")
    File.write(File.join(@export, "tokens/colors.css"), "--accent: blue;")
  end

  def sync
    _out, err, status = Open3.capture3(File.join(@root, "bin/sync"), @export)
    [status, err]
  end
end
