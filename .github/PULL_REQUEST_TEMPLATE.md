<!--
Thank you for contributing to cadence-workflow/cadence-charts.
Before you submit this pull request we'd like to make sure you are aware of our release process and best practices:

* https://github.com/cadence-workflow/cadence-charts/blob/main/CONTRIBUTING.md#release-process
* https://helm.sh/docs/chart_best_practices/
-->

<!-- markdownlint-disable-next-line first-line-heading -->
#### Description of this PR



#### Checklist

<!-- [Place an '[x]' (no spaces) in all applicable fields. Please remove unrelated fields.] -->
- [ ] `Chart.yaml`: Chart `version` bumped
- [ ] `values.yaml`: `global.image.tag` (should match with `Chart.yaml` appVersion)
- [ ] Dependencies in `Chart.yaml` (check for updates with `helm dependency update`, aim for latest major-1 stable)
- [ ] [DCO](https://github.com/cadence-workflow/cadence-charts/blob/main/CONTRIBUTING.md#sign-off-your-work) signed
- [ ] Test deployment locally
- [ ] Run `helm-docs` to update documentation