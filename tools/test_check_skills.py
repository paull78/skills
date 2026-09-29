from check_skills import MAX_CHARS, check_skill, main


def make_skill(root, name="demo", description="Does a thing. Use when asked.", body="# Demo\n", folder=None):
    d = root / (folder or name)
    d.mkdir()
    (d / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: {description}\n---\n\n{body}", encoding="utf-8"
    )
    return d


def test_valid_skill_passes(tmp_path):
    assert check_skill(make_skill(tmp_path)) == []


def test_missing_skill_file(tmp_path):
    d = tmp_path / "empty"
    d.mkdir()
    assert "missing SKILL.md" in check_skill(d)[0]


def test_name_must_match_folder(tmp_path):
    errors = check_skill(make_skill(tmp_path, name="other", folder="demo"))
    assert any("does not match folder" in e for e in errors)


def test_colon_space_in_description_is_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, description="Does things: many of them."))
    assert any("not valid YAML" in e or "': '" in e for e in errors)


def test_quoted_colon_space_is_still_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, description='"Does things: many of them."'))
    assert any("': '" in e for e in errors)


def test_space_hash_in_description_is_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, description="Counts words #fast"))
    assert any("' #'" in e for e in errors)


def test_oversize_skill_is_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, body="x" * MAX_CHARS))
    assert any("budget" in e for e in errors)


def test_main_exit_codes(tmp_path, capsys):
    good = make_skill(tmp_path, name="good")
    bad = tmp_path / "bad"
    bad.mkdir()
    assert main(["check_skills.py", str(good)]) == 0
    assert main(["check_skills.py", str(good), str(bad)]) == 1
    assert "missing SKILL.md" in capsys.readouterr().out
