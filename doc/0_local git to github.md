# step1 get a local Repository
init a local git Repository
```sh
cd ..
git init
```

or clone a Repository from git hub
```sh
git clone https://github.com/your-username/your-repository.git
```

# step2 Add Remote Repository
You need to link your local repository to your GitHub repository. If you haven't already created a repository on GitHub, create one now. Then, add it as a remote to your local repository:
```sh
git remote add origin https://github.com/your-username/your-repository.git
```

# Step3: Add and Commit Your Changes
```sh
git pull
```

modify your code ,then 

```sh
git add .
git commit -m "Initial commit or update message"
```

# Step 4: Push Changes to GitHub
```sh
git push -u origin main
```
