require 'rails_helper'

# Тест на шаблон users/show.html.erb

RSpec.describe 'users/show', type: :view do
  # Перед каждым шагом мы пропишем в переменную @users пару пользователей
  # как бы имитируя действие контроллера, который эти данные будет брать из базы
  # Обратите внимание, что мы объекты в базу не кладем, т.к. пишем FactoryGirl.build_stubbed
  context 'user show' do
    before(:each) do
      assign(:user, FactoryGirl.build_stubbed(:user, name: 'Вадик'))
      stub_template 'users/_game.html.erb' => 'User game goes here'
      render
    end

    # Проверяем, что шаблон выводит имя игрока
    it 'renders player names' do
      expect(rendered).to match 'Вадик'
    end

    # Проверяем, что шаблон выводит кнопку редактирования профиля
    it 'show edit button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    # Проверяем, что шаблон выводит фрагменты с игрой
    it 'renders game' do
      render partial: 'users/game'
      expect(rendered).to match 'User game goes here'
    end
  end
end
