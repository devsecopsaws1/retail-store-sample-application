@echo off
echo Adding changes to git...
git add src/ui/README.md
git add src/catalog/README.md
git add src/cart/README.md
git add src/orders/README.md
git add src/checkout/README.md

echo Committing changes...
git commit -m "Test CI/CD workflow - Update all service READMEs to trigger builds"

echo Pushing to gitops branch...
git push origin gitops

echo Done! Check GitHub Actions for workflow execution.
pause