feature 'Wished Product', :js do
  given(:user) { create(:user) }

  context 'add' do
    given(:product) { create(:product) }

    background do
      sign_in_as! user
    end

    scenario 'when user has a default wishlist' do
      wishlist = create(:wishlist, is_default: true, user: user)

      add_to_wishlist product

      expect(page).to have_text wishlist.name
      expect(page).to have_text product.name
    end

    scenario 'when user has no default but with non-default wishlist' do
      wishlist = create(:wishlist, is_default: false, user: user)

      add_to_wishlist product

      expect(wishlist.reload.is_default).to be true
      expect(page).to have_text wishlist.name
      expect(page).to have_text product.name
    end

    scenario 'when user has no wishlist at all' do
      expect(user.wishlists).to be_empty

      add_to_wishlist product

      expect(user.wishlists.reload.count).to eq(1)
      expect(page).to have_text user.wishlists.first.name
      expect(page).to have_text product.name
    end
  end

  context 'delete' do
    given(:wishlist) { create(:wishlist, user: user) }

    background do
      sign_in_as! user
    end

    scenario 'from a wishlist with one wished product' do
      wished_product = create(:wished_product, wishlist: wishlist)

      visit spree.wishlist_path(wishlist)

      wp_path = spree.wished_product_path(wished_product)
      delete_links = find(:xpath, '//table[@id="wishlist"]/tbody').all(:xpath, './/tr/td/p/a')
      delete_link = delete_links.select { |link| link[:href] == wp_path }.first
      delete_link.click

      expect(page).not_to have_text wished_product.variant.product.name
    end

    scenario 'randomly from a wishlist with multiple wished products while maintaining ordering by date added' do
      wished_products = [
        create(:wished_product, wishlist: wishlist),
        create(:wished_product, wishlist: wishlist),
        create(:wished_product, wishlist: wishlist)
      ]
      wished_product = wished_products.delete_at(Random.rand(wished_products.length))

      visit spree.wishlist_path(wishlist)

      wp_path = spree.wished_product_path(wished_product)
      delete_links = find(:xpath, '//table[@id="wishlist"]/tbody').all(:xpath, './/tr/td/p/a')
      delete_link = delete_links.select { |link| link[:href] == wp_path }.first
      delete_link.click
      pattern = Regexp.new(wished_products.map { |wp| wp.variant.product.name }.join('.*'))

      expect(page).not_to have_text wished_product.variant.product.name
      expect(page).to have_text pattern
    end
  end

  private

  def add_to_wishlist(product)
    visit spree.product_path(product)
    click_button 'Add to wishlist'
  end
end
