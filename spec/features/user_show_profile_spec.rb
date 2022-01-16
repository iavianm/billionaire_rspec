# Как и в любом тесте, подключаем помощник rspec-rails
require 'rails_helper'

# Начинаем описывать функционал, связанный с созданием игры
RSpec.feature 'USER show profile', type: :feature do
  # Чтобы пользователь мог посмотреть профиль другого игрока, нам надо
  # создать 2 игроков
  let(:user1) { FactoryGirl.create :user, name: 'user1', id: 1 }
  let(:user2) { FactoryGirl.create :user, name: 'user2', id: 2 }

  let!(:games) do
    FactoryGirl.create(
      :game_with_questions,
      user: user2,
      created_at: Time.new(2022,01,15,10,00),
      current_level: 14,
      prize: 500000,
    )
    FactoryGirl.create(
      :game_with_questions,
      user: user2,
      created_at: Time.new(2022,01,16,10,00),
      current_level: 14,
      prize: 500000,
    )
  end

  # Перед началом любого сценария нам надо авторизовать пользователя
  before(:each) do
    login_as user1
  end

  # Сценарий успешного создания игры
  scenario 'show profile' do
    # Заходим на главную
    visit '/'

    # Кликаем по ссылке "user2"
    click_link 'user2'

    # Ожидаем, что попадем на нужный url
    expect(page).to have_current_path "/users/#{user2.id}"

    expect(page).to have_content '500 000 ₽'
    expect(page).to have_content '15 янв., 10:00'
    expect(page).to have_content '16 янв., 10:00'
    expect(page).to have_content 'в процессе'

    expect(page).not_to have_content 'Сменить имя и пароль'
    # В процессе работы можно использовать
    # save_and_open_page
    # но в конечном коде (который вы кладете в репозиторий)
    # этого кода быть не должно, также, как и byebug
  end
end
