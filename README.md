# Github Action: Hugo Deploy to Pages

**Currently tagged as 'v1beta'. It does work quite well, but it was tested in a limited environment. Please be aware that issues could come up.**

An action for Hugo websites. Build your site from whichever repo branch you choose and deploy to a GH-Pages repo. This action supports deploying to the main site repo or to a repo submodule. No extra work is needed for submodule deploys. It's intended use is to simply automate Hugo site builds.

<a href="https://www.buymeacoffee.com/aormsby" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-green.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

## How to Use

As with any Github Action, you must include it in a workflow for your repo to run. Place the workflow at `.github/workflows/my-build-workflow.yaml` in the default repo branch. For more help, see [Github Actions documentation](https://docs.github.com/en/actions).

This action does not include the checkout step. For this, I used the [actions/checkout](https://github.com/actions/checkout) action. A token or SSH is needed for checking out private repos. See my example workflow below for details.

### Input Variables

| Name                | Required?            | Default                                 | Example                                |
| ------------------- | :------------------: | --------------------------------------- | -------------------------------------- |
| deploy_directory    | :white_check_mark:   | 'public'                                | 'public' - (hugo deploy directory name)|
| build_branch        | :white_check_mark:   | 'master'                                | 'dev' - (branch name)                  |
| deploy_branch       |                      | 'master'                                | 'live' - (branch name)                 |
| fresh_build         |                      | false                                   | true / false                           |
| do_not_delete_files |                      |                                         | 'ignore-me.txt posts static.css'.      |
| hugo_build_options  |                      |                                         | '-D --minify --ignoreCache'            |
| commit_message      |                      |                                         | 'I like big builds, and I cannot lie.' |
| git_user            |                      | 'Github Action - Hugo Build and Deploy' | 'aormsby'                              |
| git_email           |                      | 'action@github.com'                     | 'ormsbyadam@gmail.com'                 |

### Variable Notes
- **deploy_directory** -> Where you expect Hugo to output your build. Hugo builds default to 'public', but if you change that location you need to set it here. This input is also used to check if you are deploying your build to a submodule (no extra work needed).
- **build_branch** -> The branch to build from in the main project.
- **deploy_branch** -> The branch to deploy the build output to - only used if deploying to a specific branch on a submodule.
- **fresh_build** -> Clears out the specified deploy directory before running the hugo build (ignores **do_not_delete_files**).
- **do_not_delete_files** -> Treat this as a single string where each file or directory you wish to save is separated by a space. Include file extensions.
- **hugo_build_options** -> behaves the same as normal [hugo build options](https://gohugo.io/commands/hugo/)
- **commit_message** -> appends a custom commit message to the default - 'auto-build and deploy #??'

## Build and Deploy Process - Quick Overview

Right now, the `main.js` script only exists to execute `build-deploy.sh`. It's possible that future updates may add functionality. After checking out the repos and any submodules, the shell script does the following:

1. Set the git user and email config.
2. Check if you intend to deploy to a submodule or not (it's a pretty smart script).
3. Make sure the correct build and deploy branches are checked out.
4. Set the auto-build number and commit message.
5. Clear the deploy folder if **fresh_build** is set to true (skips items in **do_not_delete_files**).
6. Run `hugo` command with any options you set.
7. `git push` to deploy to the main project repo and/or the deploy submodule.
 
- The action pushes to the project repo to update any locally changed files including generated assets, which may shorten future build times. I am considering building and pushing to a new branch to avoid modifying the build branch in any way, but so far there seems to be no specific need for this.
- The action will exit quietly if there is nothing new to build (i.e. no changes in git status, no changes to commit).

**And now your changes are live!**

## Sample Workflows

**deploying to a 'live' site with default settings**
```yaml
on:
  schedule:
    - cron:  '0 7 * * 1,4'
    scheduled at 07:00 every Monday and Thursday

jobs:
  build_and_deploy_hugo_site:
    runs-on: ubuntu-latest
    name: Build and deploy Hugo site

    steps:
    # required: checkout your project repo first, submodules optional, token or SSH required for private repos
    - name: Checkout repo with submodules (theme and public)
      uses: actions/checkout@v2
      with:
        token: ${{ secrets.MY_GH_SECRET }}
        submodules: 'recursive'
    
    # required: install Hugo
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.74.3'
    
    - name: Build site with options and push to public deploy repo
      uses: aormsby/hugo-deploy-to-pages@v1beta
      with:
        # deploy_directory: 'public'
        # build_branch: 'master'
        # deploy_branch: 'master'
        fresh_build: true
        do_not_delete_files: 'testfile.txt myfolder'
        hugo_build_options: '--minify --ignoreCache'
        commit_message: 'I like big builds, and I cannot lie.'
        
    # a handy timestamp printout
    - name: Timestamp
      run: date
```

**alternatively, if you want to build and deploy to a different output folder on a dev branch**
```yaml
on:
  schedule:
    - cron:  '0 7 * * 1,4'
    scheduled at 07:00 every Monday and Thursday

jobs:
  build_and_deploy_hugo_site:
    runs-on: ubuntu-latest
    name: Build and deploy Hugo site

    steps:
    # required: checkout your project repo first, submodules optional, token or SSH required for private repos
    - name: Checkout repo with submodules (theme and public)
      uses: actions/checkout@v2
      with:
        token: ${{ secrets.MY_GH_SECRET }}
        submodules: 'recursive'
    
    # required: install Hugo
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.74.3'
    
    - name: Build site with options and push to public deploy repo
      uses: aormsby/hugo-deploy-to-pages@v1beta
      with:
        deploy_directory: 'documents'
        build_branch: 'dev'   # note: these do not have to match
        deploy_branch: 'dev'
        hugo_build_options: '--buildDrafts'
        commit_message: 'I like dev builds, and I cannot lie.'
        
    # a handy timestamp printout
    - name: Timestamp
      run: date
```
