# Github Action: Hugo Deploy to Pages

**Currently tagged as 'v1beta'. It does work quite well, but it was tested in a limited environment. Please be aware that issues could come up.**

An action for Hugo websites. Build your site from whichever repo branch you choose and deploy to a GH-Pages repo. This action supports deploying to the main site repo or to a repo submodule. No extra work is needed for submodule deploys. It's intended use is to simply automate Hugo site builds.

<a href="https://www.buymeacoffee.com/aormsby" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-green.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

## How to Use

As with any Github Action, you must include it in a workflow for your repo to run. Place the workflow at `.github/workflows/my-build-workflow.yaml` in the default repo branch. For more help, see [Github Actions documentation](https://docs.github.com/en/actions).

For git checkout and Hugo install steps, I use [actions/checkout](https://github.com/actions/checkout) and [peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo). A token or SSH is needed for checking out private repos. See my example workflow below for details.

### Input Variables

#### Primary Input

| Name                      | Required?            | Default  | Example                                |
| ------------------------- | :----------------: | -----------| -------------------------------------- |
| hugo_publish_directory    | :white_check_mark: |            | 'public' - (hugo publishDir value)     |
| source_branch             | :white_check_mark: |            | 'main' - (branch name)                 |
| deploy_branch             | :white_check_mark: |            | 'release' - (branch name)              |
| submodule_branch          |                    |            | 'main'                                 |

#### Advanccd Options

| Name                   | Required?   | Default                                 | Example                                   |
| ---------------------- | :---------: | --------------------------------------- | ----------------------------------------- |
| fresh_build            |             | false                                   | true / false                              |
| do_not_delete_files    |             |                                         | 'ignore-me.txt posts static.css'          |
| hugo_build_options     |             |                                         | '-D --minify --ignoreCache'               |
| commit_message         |             |                                         | 'I like big builds, and I cannot lie.'    |
| git_user               |             | 'Action - Hugo Build and Deploy'        | 'aormsby'                                 |
| git_email              |             | 'action@github.com'                     | 'ormsbyadam@gmail.com'                    |
| source_merge_args      |             | '-s recursive -Xtheirs'                 | '-s recursive -Xtheirs'                   |

### Variable Notes

- **hugo_publish_directory** -> Where you expect Hugo to output your build. Hugo's publishDir default is 'public', but if you change that location you need to set it here for the action to run properly.

- **source_branch** -> The branch to grab build source code from.

- **deploy_branch** -> The name of the desired deploy branch. It will contain your entire build history.

- **submodule_branch** -> If your publish directory is a link to a git submodule (another repo), you need to include the desired branch of the submodule for the deploy here. **Only set this input if you're deploying to a submodule!**

- **fresh_build** -> Clears out the publish directory before running the hugo build command (ignores items in **do_not_delete_files**).

- **do_not_delete_files** -> Treat this as a single string where each file or directory you wish to persist is separated by a space. Include file extensions. These files are always ignored -- '. .. .git CNAME'

- **hugo_build_options** -> Behaves the same as normal [hugo build options](https://gohugo.io/commands/hugo/)

- **commit_message** -> Appends a custom commit message to the default - 'auto-build #{build number} - {source branch} @ {commit_hash}'

- **source_merge_args** -> Options for merging data from the source branch into the deploy branch. Default values will automatically favor the source files for a clean build. It's not recommended to change this.

## Build and Deploy Process - Quick Overview

Right now, the `main.js` script only exists to execute `build-deploy.sh`. It's possible that future updates may add functionality. After checking out the repos and any submodules, the shell script does the following:

1. Configure git user and email in the runner environment.
2. Make sure the correct source and deploy branches are checked out.
3. Set the auto-build number and commit message.
4. Merge from source branch into deploy branch. (Choose conflict overwrites from the source.)
5. Clear the deploy folder if **fresh_build** is set to true (skips items in **do_not_delete_files**).
6. Run `hugo` command with any options you set.
7. `git push` to deploy to the desired deploy location.

**And now your changes are live!**

**Note:** This action will exit quietly if there is nothing new to build (i.e. no changes in git status, no changes to commit).

## Sample Workflows

### Deploying to a live site with simple settings

```yaml
on:
  schedule:
    - cron:  '0 7 * * 1,4'
    # scheduled at 07:00 every Monday and Thursday
  workflow_dispatch:
    # for manual builds

jobs:
  build_and_deploy_hugo_site:
    runs-on: ubuntu-latest
    name: Build and deploy Hugo site

    steps:
     # Step 1: checkout your project repo
    - name: Checkout repo with submodules (theme and public-sub)
      uses: actions/checkout@v2
      with:
        token: ${{ secrets.YOUR_SSECRET_HERE }}
        submodules: 'recursive'
    
     # Step 2: Install Hugo
    - name: Install Hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.74.3'  # your Hugo version here
    
     # Step 3: Build and deploy with this action
    - name: Build Hugo site and deploy
      uses: aormsby/hugo-deploy-to-pages@v2
      with:
        hugo_publish_directory: 'public'
        source_branch: 'main'
        deploy_branch: 'live'
        commit_message: 'I like big builds, and I cannot lie.'
        
     # Step 4: a handy timestamp printout, just because
    - name: Timestamp
      run: date
```

### Some non-default options

```yaml
     # Step 3: Build and deploy with this action
    - name: Build Hugo site and deploy
      uses: aormsby/hugo-deploy-to-pages@v2
      with:
        hugo_publish_directory: 'public-submod'
        source_branch: 'main'
        deploy_branch: 'live'
        commit_message: 'I like big submodule builds, and I cannot lie.'
        submodule_branch: 'main'  # setting this pushes to submodule!
        fresh_build: true
        do_not_delete_files: 'gnore-me.txt posts static.css'
        hugo_build_options: '--buildDrafts --minify'
```
