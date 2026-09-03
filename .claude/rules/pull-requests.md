# Rules: Pull requests

The body follows `.github/PULL_REQUEST_TEMPLATE.md`. Which branch a PR targets and what the
version has to do are in [release.md](release.md).

- **Short and high-level.** A concise report of what changes for a consumer and why — the key
  points and the *why*, not a walkthrough of the code. The reviewer is going to read the diff;
  they need the description to tell them what the diff is *for*. No file-by-file list, no test
  counts, no checklist the repo does not ask for.
- **Describe the whole PR, not your last commit.** The description covers everything between the
  target branch and the head — `git log <base>..HEAD` is the scope. When a PR carries commits
  someone else pushed, or an earlier commit of your own, that work is part of what the PR
  delivers and belongs in the description. **Never** write "the previous commit did X" about
  something this PR is itself delivering; a reader of the PR sees one change, not your sequence
  of commits.
- **Two sections, the template's**: *Motivation* — why the change is necessary, the problem or
  need behind it; *Proposed solution* — how that necessity is solved, at the altitude of a
  consumer's experience. Don't add sections the template does not have.
- **Name every breaking change explicitly**, with the mechanical migration, in the same words as
  its `CHANGELOG.md` entry — a reviewer should see the version consequence without diffing the
  changelog ([release.md](release.md), [public-api.md](public-api.md)).
- **A new dependency states its reason here**, including a move between `only:` environments
  ([dependencies.md](dependencies.md)).
- English, like every other word we write ([docs.md](docs.md)).
