import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureTabBar()
    }
    
    private func configureTabBar() {
        tabBar.isTranslucent = false
        tabBar.backgroundImage = UIImage()  
        tabBar.shadowImage = UIImage()
        tabBar.barTintColor = .white
        tabBar.backgroundColor = .white
    }

    private func setupTabs() {
        let homeVC = createNavController(viewController: HomeViewController(), title: "Home", imageName: "magnifyingglass")
        let rentVC = createNavController(viewController: RentHomeViewController(), title: "Rent", imageName: "cart.fill")
        let libraryVC = createNavController(viewController: LibraryViewController(), title: "Library", imageName: "books.vertical.fill")
        let profileVC = createNavController(viewController: ProfileViewController(), title: "Profile", imageName: "person.fill")

        viewControllers = [homeVC, rentVC, libraryVC, profileVC]
    }

    private func createNavController(viewController: UIViewController, title: String, imageName: String) -> UINavigationController {
        viewController.view.backgroundColor = .white
        viewController.title = title
        viewController.navigationItem.largeTitleDisplayMode = .always

        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.prefersLargeTitles = true
        navController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: imageName), tag: 0)

        return navController
    }
}
